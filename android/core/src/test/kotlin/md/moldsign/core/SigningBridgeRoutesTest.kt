package md.moldsign.core

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.security.cert.X509Certificate
import java.util.Base64
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLSocket
import javax.net.ssl.X509TrustManager

/** The browser-facing routes of the bridge (docs/04): certificate list, async signing, long-poll, PIN sessions. */
class SigningBridgeRoutesTest {
    private val cert = CertificateSummary.parse(TestCertificates.mdQSign)
    private val card = BridgeCard("reader-1", cert)
    private val portal = "https://msign.gov.md"
    private val pdf = "%PDF-1.7 test".toByteArray()
    private val closeables = mutableListOf<AutoCloseable>()

    @After
    fun tearDown() = closeables.forEach { it.close() }

    /** Stand-in for [CardSigningService]: asks consent like the real one and "signs" by prefixing the input. */
    private class FakeService(private val summary: CertificateSummary) : SigningService {
        override val readerState: StateFlow<ReaderState> = MutableStateFlow(ReaderState.NoReader)
        override val progress: StateFlow<SigningStep> = MutableStateFlow(SigningStep.Idle)
        val requesters = mutableListOf<String?>()
        val pinsSeen = mutableListOf<String>()
        val xadesCalls = mutableListOf<String>()

        override fun certificate(reader: String?) = summary

        override fun signPdf(input: Document, consent: Consent, requester: String?, reader: String?, expectedCertificateSha1: String?): SignResult {
            requesters += requester
            val answer = consent.obtain(ConsentRequest(requester, listOf(input.name), "PAdES-T", summary))
            if (answer !is ConsentResult.Pin) throw CardError.Cancelled()
            pinsSeen += String(answer.pin)
            answer.pin.fill('\u0000')
            return SignResult("signed:".toByteArray() + input.bytes, summary, "PAdES-T")
        }

        override fun signXades(
            files: List<Document>, level: XadesLevel, packaging: XadesPackaging, consent: Consent,
            requester: String?, reader: String?, expectedCertificateSha1: String?, digest: XadesDigest,
        ): SignResult {
            requesters += requester
            xadesCalls += "$level/$packaging/$digest/${files.single().name}"
            val answer = consent.obtain(ConsentRequest(requester, files.map { it.name }, "XAdES-${level.name}", summary))
            if (answer !is ConsentResult.Pin) throw CardError.Cancelled()
            answer.pin.fill('\u0000')
            return SignResult("<xades/>".toByteArray(), summary, "XAdES-${level.name}")
        }

        override fun signDigestInfo(
            digestInfo: ByteArray, documentName: String, consent: Consent,
            requester: String?, reader: String?, expectedCertificateSha1: String?,
        ): RawSignature = TODO("unused")

        override fun verify(file: Document, detachedDocuments: List<Document>): List<ValidationReport> = TODO("unused")
    }

    private fun routes(consent: Consent, cards: List<BridgeCard> = listOf(card), service: FakeService = FakeService(cert)) =
        SigningBridgeRoutes(service, { cards }, consent, pollTimeoutMs = 10_000).also { closeables += it }

    private fun askPin(pin: String = "1234", counter: IntArray = IntArray(1)) = Consent { _ ->
        counter[0]++
        ConsentResult.Pin(pin.toCharArray())
    }

    private fun request(method: String, path: String, query: String? = null, body: String = "", origin: String? = portal, host: String = "localhost.cts.md:18443") =
        BridgeRequest(
            method, path, query,
            listOfNotNull("host" to host, origin?.let { "origin" to it }).toMap(),
            body.toByteArray(),
        )

    private fun signBody(data: ByteArray = pdf, contentType: String = "pdf", sha1Cert: ByteArray? = cert.der) =
        """{"data":"${Base64.getEncoder().encodeToString(data)}","contentType":"$contentType","signFormat":"PAdES-T",""" +
            """"signatureType":"Embedded","algorithm":"SHA256","certificate":{"certificateBase64":"${sha1Cert?.let { Base64.getEncoder().encodeToString(it) }.orEmpty()}"},"pin":""}"""

    private fun BridgeResponse.header(name: String) = headers.firstOrNull { it.first.equals(name, ignoreCase = true) }?.second

    private fun BridgeResponse.text() = String(body, Charsets.UTF_8)

    private fun BridgeResponse.signedBytes(): ByteArray {
        val json = MiniJson.parse(text()) as Map<*, *>
        return Base64.getDecoder().decode(json["base64File"] as String)
    }

    private fun sessionOf(created: BridgeResponse): String = created.header("sessionId")!!

    @Test
    fun hostErrorPresentationDoesNotExposeTechnicalFailure() {
        val r = SigningBridgeRoutes(FakeService(cert), { listOf(card) }, askPin(),
            errorMessage = { "Authentication could not be completed." },
            withSigningService = { _, _, _, _ -> throw IllegalStateException("APDU internal failure") })
            .also { closeables += it }
        val id = sessionOf(r.handle(request("POST", "/sign/data", body = signBody())))
        val response = r.handle(request("GET", "/sign/data/PKCS11/$id/Any"))
        assertEquals(400, response.status)
        assertTrue(response.text().contains("Authentication could not be completed."))
        assertFalse(response.text().contains("APDU"))
        assertFalse(response.header("error")!!.contains("APDU"))
    }

    @Test
    fun onDemandIdentityListsWithoutOpeningAndUsesSessionService() {
        val fallback = FakeService(cert)
        val contactless = FakeService(cert)
        var openings = 0
        val r = SigningBridgeRoutes(fallback, { listOf(BridgeCard("nfc:${cert.sha1Hex}", cert)) }, askPin(),
            withSigningService = { selected, request, consent, operation ->
                openings++
                assertEquals(cert.sha1Hex, selected.certificate.sha1Hex)
                val answer = consent.obtain(request) as ConsentResult.Pin
                try { operation(contactless, Consent { ConsentResult.Pin(answer.pin.copyOf()) }) }
                finally { answer.pin.fill('\u0000') }
            }).also { closeables += it }
        assertEquals(200, r.handle(request("GET", "/certificates")).status)
        assertEquals(0, openings)
        val id = sessionOf(r.handle(request("POST", "/sign/data", body = signBody())))
        assertEquals(200, r.handle(request("GET", "/sign/data/PKCS11/$id/Any")).status)
        assertEquals(1, openings)
        assertTrue(fallback.pinsSeen.isEmpty())
        assertEquals(listOf("1234"), contactless.pinsSeen)
    }

    @Test
    fun onDemandCancellationNeverFallsBackToReader() {
        val fallback = FakeService(cert)
        var openings = 0
        val r = SigningBridgeRoutes(fallback, { listOf(BridgeCard("nfc:${cert.sha1Hex}", cert)) }, askPin(),
            withSigningService = { _, _, _, _ -> openings++; throw CardError.Cancelled() })
            .also { closeables += it }
        val id = sessionOf(r.handle(request("POST", "/sign/data", body = signBody())))
        assertEquals(400, r.handle(request("GET", "/sign/data/PKCS11/$id/Any")).status)
        assertEquals(1, openings)
        assertTrue(fallback.pinsSeen.isEmpty())
    }

    @Test
    fun certificatesListsEveryReadyCardWithItsCertificate() {
        val r = routes(askPin()).handle(request("GET", "/certificates"))
        assertEquals(200, r.status)
        val models = ((MiniJson.parse(r.text()) as Map<*, *>)["certificateModel"] as List<*>)
        assertEquals(1, models.size)
        val m = models.single() as Map<*, *>
        assertEquals(cert.sha1Hex, m["certificateId"])
        assertEquals(cert.subjectDn, m["subjectDN"])
        assertEquals(true, m["privateKeyPresent"])
        assertArrayEquals(TestCertificates.mdQSign, Base64.getDecoder().decode(m["certificateBase64"] as String))
    }

    @Test
    fun certificatesIsEmptyJsonWithoutCards() {
        val r = routes(askPin(), cards = emptyList()).handle(request("GET", "/certificates"))
        assertEquals("""{"certificateModel":[]}""", r.text())
    }

    @Test
    fun signDataAnswers201WithAbsoluteLocationAndEmptyBodyThenLongPollsTheResult() {
        val service = FakeService(cert)
        val r = routes(askPin(), service = service)

        val created = r.handle(request("POST", "/sign/data", body = signBody()))

        assertEquals(201, created.status)
        assertEquals(0, created.body.size)
        val id = sessionOf(created)
        assertEquals("https://localhost.cts.md:18443/sign/data/PKCS11/$id/Any", created.header("Location"))

        // A second allowed origin cannot consume the result, even knowing its identifier.
        assertEquals(404, r.handle(request("GET", "/sign/data/PKCS11/$id/Any", origin = "https://mpass.gov.md")).status)
        assertEquals(404, r.handle(request("GET", "/sign/data/PKCS11/$id/Any", origin = null)).status)
        val done = r.handle(request("GET", "/sign/data/PKCS11/$id/Any"))
        assertEquals(200, done.status)
        assertArrayEquals("signed:".toByteArray() + pdf, done.signedBytes())
        assertEquals(listOf<String?>(portal), service.requesters)
        // answered once: the session is gone
        assertEquals(404, r.handle(request("GET", "/sign/data/PKCS11/$id/Any")).status)
    }

    @Test
    fun pollWaitsForTheUserInsteadOfRedirecting() {
        val asked = CountDownLatch(1)
        val answer = CountDownLatch(1)
        val r = routes(Consent { _ ->
            asked.countDown()
            answer.await(5, TimeUnit.SECONDS)
            ConsentResult.Pin("1234".toCharArray())
        })
        val id = sessionOf(r.handle(request("POST", "/sign/data", body = signBody())))
        var response: BridgeResponse? = null
        val poller = Thread { response = r.handle(request("GET", "/sign/data/PKCS11/$id/Any")) }.apply { start() }

        assertTrue(asked.await(5, TimeUnit.SECONDS))
        poller.join(300)
        assertTrue("the poll is held while the PIN sheet is open", poller.isAlive)
        answer.countDown()
        poller.join(5_000)

        assertEquals(200, response?.status)
    }

    @Test
    fun cancelledConsentIsA400WithTheErrorHeader() {
        val r = routes(Consent { ConsentResult.Cancelled })
        val id = sessionOf(r.handle(request("POST", "/sign/data", body = signBody())))

        val done = r.handle(request("GET", "/sign/data/PKCS11/$id/Any"))

        assertEquals(400, done.status)
        assertEquals("user denied the signing request", done.header("error"))
        assertTrue(done.text().contains("user denied the signing request"))
    }

    @Test
    fun aBatchReusesThePinOfItsFirstDocumentForTheSameOriginAndCard() {
        val asked = IntArray(1)
        val service = FakeService(cert)
        val r = routes(askPin(counter = asked), service = service)

        val first = sessionOf(r.handle(request("POST", "/sign/data", body = signBody())))
        assertEquals(200, r.handle(request("GET", "/sign/data/PKCS11/$first/Any", query = "keep_pin_session=1")).status)
        val second = sessionOf(r.handle(request("POST", "/sign/data", query = "use_pin_session=$first", body = signBody())))
        assertEquals(200, r.handle(request("GET", "/sign/data/PKCS11/$second/Any")).status)

        assertEquals("one consent + PIN covers the batch", 1, asked[0])
        assertEquals(listOf("1234", "1234"), service.pinsSeen)

        // another origin never gets the PIN of the batch
        val foreign = sessionOf(r.handle(request("POST", "/sign/data", query = "use_pin_session=$first", body = signBody(), origin = "https://mpass.gov.md")))
        r.handle(request("GET", "/sign/data/PKCS11/$foreign/Any", origin = "https://mpass.gov.md"))
        assertEquals(2, asked[0])
    }

    @Test
    fun aPollWithoutKeepEndsThePinSession() {
        val asked = IntArray(1)
        val r = routes(askPin(counter = asked))

        val first = sessionOf(r.handle(request("POST", "/sign/data", body = signBody())))
        r.handle(request("GET", "/sign/data/PKCS11/$first/Any")) // no keep_pin_session
        val second = sessionOf(r.handle(request("POST", "/sign/data", query = "use_pin_session=$first", body = signBody())))
        r.handle(request("GET", "/sign/data/PKCS11/$second/Any"))

        assertEquals(2, asked[0])
    }

    @Test
    fun noCertificateMeansTheOnlyConnectedCard() {
        val r = routes(askPin())
        val id = sessionOf(r.handle(request("POST", "/sign/data", body = signBody(sha1Cert = null))))

        assertEquals(200, r.handle(request("GET", "/sign/data/PKCS11/$id/Any")).status)

        val two = routes(askPin(), cards = listOf(card, BridgeCard("reader-2", CertificateSummary.parse(TestCertificates.mdTrustCa))))
        val ambiguous = sessionOf(two.handle(request("POST", "/sign/data", body = signBody(sha1Cert = null))))
        assertEquals(400, two.handle(request("GET", "/sign/data/PKCS11/$ambiguous/Any")).status)
    }

    @Test
    fun aCertificateOfAnotherCardFailsWithoutAskingForAPin() {
        val asked = IntArray(1)
        val r = routes(askPin(counter = asked))
        val id = sessionOf(r.handle(request("POST", "/sign/data", body = signBody(sha1Cert = TestCertificates.mdTrustCa))))

        val done = r.handle(request("GET", "/sign/data/PKCS11/$id/Any"))

        assertEquals(400, done.status)
        assertEquals(0, asked[0])
    }

    @Test
    fun xmlContentGoesToXadesWithTheRequestedDigestAndPackaging() {
        val service = FakeService(cert)
        val r = routes(askPin(), service = service)
        val xml = "<a/>".toByteArray()
        val body = signBody(data = xml, contentType = "xml").replace("\"PAdES-T\"", "\"XAdES-C\"").replace("\"SHA256\"", "\"SHA-1\"")
        val id = sessionOf(r.handle(request("POST", "/sign/data", body = body)))

        val done = r.handle(request("GET", "/sign/data/PKCS11/$id/Any"))

        assertEquals(200, done.status)
        assertArrayEquals("<xades/>".toByteArray(), done.signedBytes())
        assertEquals(listOf("C/Enveloping/SHA1/document.xml"), service.xadesCalls) // "Embedded" = enveloping
    }

    @Test
    fun badBodiesAndFilePathRoutes() {
        val r = routes(askPin())
        assertEquals(400, r.handle(request("POST", "/sign/data", body = "not json")).status)
        assertEquals(400, r.handle(request("POST", "/sign/data", body = """{"contentType":"pdf"}""")).status)
        assertEquals(501, r.handle(request("POST", "/sign/file", body = "{}")).status)
        assertEquals(404, r.handle(request("GET", "/nope")).status)
        assertEquals(404, r.handle(request("GET", "/sign/data/PKCS11/missing/Any")).status)
    }

    @Test
    fun observerSeesStartAndOutcome() {
        val events = mutableListOf<String>()
        val observer = object : BridgeObserver {
            override fun signStarted(origin: String?) {
                events += "start $origin"
            }

            override fun signFinished(origin: String?, format: String, error: Throwable?) {
                events += "end $format ${error?.javaClass?.simpleName}"
            }
        }
        val r = SigningBridgeRoutes(FakeService(cert), { listOf(card) }, Consent { ConsentResult.Cancelled }, observer, pollTimeoutMs = 10_000)
            .also { closeables += it }
        val id = sessionOf(r.handle(request("POST", "/sign/data", body = signBody())))
        r.handle(request("GET", "/sign/data/PKCS11/$id/Any"))

        assertEquals(listOf("start $portal", "end PAdES-T Cancelled"), events)
    }
}

/** HTTPS listener with the vendor `localhost.cts.md` identity (docs/04, docs/06). */
class BridgeTlsTest {
    private val policy = BridgeOriginPolicy.fromProperties(SpecFiles.read("spec/bridge/allowed-origins.properties"))

    @Test
    fun httpsListenerPresentsTheVendorIdentityAndAnswers() {
        val tls = requireNotNull(BridgeTls.vendorContext()) { "localhost.p12 is not packaged into the core jar" }
        BridgeServer(policy, port = 0, tls = tls).use { server ->
            val port = server.start()
            val trustAll = object : X509TrustManager {
                override fun checkClientTrusted(chain: Array<X509Certificate>, authType: String) = Unit
                override fun checkServerTrusted(chain: Array<X509Certificate>, authType: String) = Unit
                override fun getAcceptedIssuers(): Array<X509Certificate> = emptyArray()
            }
            val client = SSLContext.getInstance("TLS").apply { init(null, arrayOf(trustAll), null) }
            (client.socketFactory.createSocket("127.0.0.1", port) as SSLSocket).use { socket ->
                socket.soTimeout = 5_000
                socket.startHandshake()
                val chain = socket.session.peerCertificates.map { it as X509Certificate }
                assertEquals("CN=localhost.cts.md", chain.first().subjectX500Principal.name)
                assertTrue("the intermediates are sent too", chain.size >= 2)
                socket.outputStream.write("GET /certificates HTTP/1.1\r\nHost: localhost.cts.md\r\nOrigin: https://msign.gov.md\r\n\r\n".toByteArray())
                socket.outputStream.flush()
                val text = socket.inputStream.readBytes().toString(Charsets.ISO_8859_1)
                assertTrue(text, text.startsWith("HTTP/1.1 200 OK"))
                assertFalse(text.contains("Access-Control-Allow-Origin: *"))
            }
        }
    }
}
