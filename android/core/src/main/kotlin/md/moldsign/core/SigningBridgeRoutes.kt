package md.moldsign.core

import java.io.Closeable
import java.net.URLDecoder
import java.security.SecureRandom
import java.util.Base64
import java.util.concurrent.CompletableFuture
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ExecutionException
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException

/** A card the browser may sign with: an inserted card whose certificate is already read (the wallet's ready cards). */
class BridgeCard(val readerId: String, val certificate: CertificateSummary) {
    val der: ByteArray get() = certificate.der ?: error("certificate DER not kept")
}

/** What the host (Android: the status light and the activity list) wants to know about bridge signatures. */
interface BridgeObserver {
    fun signStarted(origin: String?) {}

    /** [format] is `PAdES-T`, `XAdES-T`, …; [error] is `null` on success (a cancelled request included as [CardError.Cancelled]). */
    fun signFinished(origin: String?, format: String, error: Throwable?) {}
}

/**
 * The browser-facing routes of the MoldSign Server replica (docs/04): `GET /certificates` and the async
 * `POST /sign/data` + long-poll `GET /sign/data/PKCS11/<id>/Any` the msign.gov.md portal uses. Port of the Swift
 * `MoldSignServer` routes, sessions and PIN sessions (Bridge/Server.swift).
 *
 * - `POST /sign/data` answers `201 Created` with an ABSOLUTE `Location` and a `sessionId` header and an EMPTY body:
 *   mpass's jQuery code continues only from `.fail`, i.e. when the empty body does not parse as JSON.
 * - The `GET` on the Location is a long-poll: answered only when the session has finished (`200 {"base64File":…}`,
 *   or `400` + `error` header). Never a 303 loop: browsers follow at most 20 redirects and consent + PIN take longer.
 * - Jobs run one at a time in arrival order, so a portal batch keeps its order and the PIN of its first document
 *   (`use_pin_session`) is known when the next one starts. The PIN is kept in memory only, for the same origin
 *   and the same card, [PIN_SESSION_TTL_MS] after its last use.
 * - The user's consent (SEC-02) is [consent]: it shows who asks, the document and the card, and returns the PIN.
 *   A PIN typed into the web page is ignored: the PIN is only ever entered in the app.
 *
 * `/sign/pdf`, `/sign/file` and the verify routes take file paths of the vendor desktop suite; they answer 501 here.
 */
class SigningBridgeRoutes(
    private val service: SigningService,
    private val cards: () -> List<BridgeCard>,
    private val consent: Consent,
    private val observer: BridgeObserver = object : BridgeObserver {},
    private val clock: () -> Long = System::currentTimeMillis,
    private val pollTimeoutMs: Long = POLL_TIMEOUT_MS,
    private val log: (String) -> Unit = {},
) : BridgeRoutes, Closeable {
    private class Outcome(val payload: String, val error: String?)

    private class Session(val createdAt: Long) {
        val outcome = CompletableFuture<Outcome>()
    }

    private class PinSession(val pin: CharArray, val certificateSha1: String, val origin: String?, var lastUse: Long)

    private val sessions = ConcurrentHashMap<String, Session>()
    private val pinSessions = HashMap<String, PinSession>()
    private val jobs: ExecutorService = Executors.newSingleThreadExecutor { r -> Thread(r, "bridge-sign").apply { isDaemon = true } }
    private val random = SecureRandom()

    override fun handle(request: BridgeRequest): BridgeResponse {
        val path = request.path.trimEnd('/').ifEmpty { "/" }
        return when {
            request.method == "GET" && path == "/certificates" -> certificates()
            request.method == "POST" && path == "/sign/data" -> startSignData(request)
            request.method == "GET" && path.startsWith("/sign/data/PKCS11/") -> poll(request, path)
            UNSUPPORTED_ROUTES.any { path == it || path.startsWith("$it/") } ->
                BridgeResponse.json(501, """{"error":"file-path routes are not available in the Android app"}""")
            else -> BridgeResponse.json(404, """{"error":"not found"}""")
        }
    }

    override fun close() {
        jobs.shutdownNow()
        sessions.values.forEach { it.outcome.complete(Outcome("""{"error":"bridge stopped"}""", "bridge stopped")) }
        sessions.clear()
        synchronized(pinSessions) {
            pinSessions.values.forEach { it.pin.fill('\u0000') }
            pinSessions.clear()
        }
    }

    // ------------------------------------------------------------------ /certificates

    /**
     * Every ready card (several can be connected), like the vendor's GlobalCertificateProvider. Built with proper
     * JSON escaping: the portal shows "no available signatures" for an empty list OR for a body it cannot parse.
     */
    private fun certificates(): BridgeResponse {
        val models = cards().mapIndexed { index, card ->
            val c = card.certificate
            val label = c.commonName + ByteArray(2).also(random::nextBytes).toHex()
            "{" + listOf(
                "certificateId" to MiniJson.quote(c.sha1Hex),
                "label" to MiniJson.quote(label),
                "providerId" to MiniJson.quote("libbit4xpki.so-$index"),
                "policy" to MiniJson.quote("1.2.498.3.32.1.1"),
                "certificateName" to MiniJson.quote("${c.commonName} (null) (1.2.498.3.32.1.1)"),
                "subjectDN" to MiniJson.quote(c.subjectDn),
                "issuerDN" to MiniJson.quote(c.issuerDn),
                "authority" to "false",
                "trusted" to "true",
                "verified" to "0",
                "privateKeyPresent" to "true",
                "certificateBase64" to MiniJson.quote(Base64.getEncoder().encodeToString(card.der)),
            ).joinToString(",") { (k, v) -> "\"$k\":$v" } + "}"
        }
        return BridgeResponse.json(200, """{"certificateModel":[${models.joinToString(",")}]}""")
    }

    // ------------------------------------------------------------------ /sign/data

    @Suppress("UNCHECKED_CAST")
    private fun startSignData(request: BridgeRequest): BridgeResponse {
        val body = try {
            MiniJson.parse(String(request.body, Charsets.UTF_8)) as? Map<String, Any?>
        } catch (e: RuntimeException) {
            null
        } ?: return BridgeResponse.json(400, """{"error":"invalid JSON"}""")
        val raw = (body["data"] as? String)?.let { runCatching { Base64.getMimeDecoder().decode(it) }.getOrNull() }
            ?: return BridgeResponse.json(400, """{"error":"missing data"}""")
        val contentType = (body["contentType"] as? String).orEmpty()
        val signFormat = (body["signFormat"] as? String) ?: "XAdES-T"
        // An empty certificate (the portal sends none for "any card") means: the only connected card.
        val certificateDer = ((body["certificate"] as? Map<String, Any?>)?.get("certificateBase64") as? String)
            ?.let { runCatching { Base64.getMimeDecoder().decode(it) }.getOrNull() }
            ?.takeIf { it.isNotEmpty() }
        val job = SignJob(
            origin = request.header("origin"),
            data = raw,
            pdf = contentType.equals("pdf", ignoreCase = true),
            signFormat = signFormat,
            enveloping = (body["signatureType"] as? String) != "Detached",
            digest = XadesDigest.fromRequested(body["algorithm"] as? String),
            certificateSha1 = certificateDer?.let { Sha.sha1(it).toHex() },
            usePinSession = queryItems(request.query)["use_pin_session"],
        )

        sweep()
        val id = ByteArray(12).also(random::nextBytes).toHex()
        val session = Session(clock())
        sessions[id] = session
        try {
            jobs.execute { session.outcome.complete(run(id, job)) }
        } catch (e: java.util.concurrent.RejectedExecutionException) {
            sessions.remove(id)
            return BridgeResponse.json(500, """{"error":"bridge stopped"}""")
        }
        val host = request.header("host") ?: "localhost.cts.md:${BridgeServer.DEFAULT_TLS_PORT}"
        return BridgeResponse(
            201, ByteArray(0), "text/plain",
            listOf("Location" to "https://$host/sign/data/PKCS11/$id/Any", "sessionId" to id),
        )
    }

    private class SignJob(
        val origin: String?,
        val data: ByteArray,
        val pdf: Boolean,
        val signFormat: String,
        val enveloping: Boolean,
        val digest: XadesDigest,
        val certificateSha1: String?,
        val usePinSession: String?,
    ) {
        val format: String get() = if (pdf) CardSigningService.FORMAT_PADES_T else signFormat
    }

    /** Runs on the single signing thread: select the card, consent + PIN (or reuse), sign, remember the PIN. */
    private fun run(id: String, job: SignJob): Outcome {
        observer.signStarted(job.origin)
        var capturedPin: CharArray? = null
        var reused: CharArray? = null
        try {
            val card = pickCard(job.certificateSha1)
            reused = job.usePinSession?.let { reusablePin(it, job.origin, card.certificate.sha1Hex) }
            val reusable = reused
            val sessionConsent = Consent { request ->
                if (reusable != null) {
                    ConsentResult.Pin(reusable.copyOf())
                } else {
                    consent.obtain(request).also { if (it is ConsentResult.Pin) capturedPin = it.pin.copyOf() }
                }
            }
            val result = if (job.pdf) {
                service.signPdf(Document("document.pdf", job.data), sessionConsent, job.origin, card.readerId, card.certificate.sha1Hex)
            } else {
                val level = when (job.signFormat) {
                    "XAdES-BES" -> XadesLevel.BES
                    "XAdES-C" -> XadesLevel.C
                    else -> XadesLevel.T
                }
                val packaging = if (job.enveloping) XadesPackaging.Enveloping else XadesPackaging.Detached
                service.signXades(listOf(Document("document.xml", job.data)), level, packaging, sessionConsent, job.origin, card.readerId, card.certificate.sha1Hex, job.digest)
            }
            (capturedPin ?: reused)?.let { rememberPin(id, it, result.certificate.sha1Hex, job.origin) }
            observer.signFinished(job.origin, job.format, null)
            return Outcome("""{"base64File":"${Base64.getEncoder().encodeToString(result.output)}"}""", null)
        } catch (e: Throwable) {
            val message = describe(e)
            log("sign failed: ${e.javaClass.simpleName}: ${e.message}")
            observer.signFinished(job.origin, job.format, e)
            return Outcome("""{"error":${MiniJson.quote(message)}}""", message)
        } finally {
            capturedPin?.fill('\u0000')
            reused?.fill('\u0000')
        }
    }

    private fun pickCard(certificateSha1: String?): BridgeCard {
        val available = cards()
        if (available.isEmpty()) throw CardError.NoCard("No card connected")
        if (certificateSha1 == null) {
            return available.singleOrNull() ?: throw CardError.Format("Several cards are connected: select a certificate")
        }
        return available.firstOrNull { it.certificate.sha1Hex.equals(certificateSha1, ignoreCase = true) }
            ?: throw CardError.NoCard("The card of the selected certificate is not connected")
    }

    private fun describe(e: Throwable): String = when (e) {
        is CardError.Cancelled -> "user denied the signing request"
        is NotImplementedError -> "this signature format is not supported by the Android app yet"
        else -> e.message?.takeIf { it.isNotBlank() } ?: e.javaClass.simpleName
    }

    // ------------------------------------------------------------------ long-poll

    private fun poll(request: BridgeRequest, path: String): BridgeResponse {
        val id = path.split('/').filter { it.isNotEmpty() }.getOrNull(3).orEmpty()
        val keepPin = queryItems(request.query)["keep_pin_session"] == "1"
        val session = sessions[id]
            ?: return BridgeResponse.json(404, """{"error":"unknown session"}""", listOf("error" to "unknown session"))
        val outcome = try {
            session.outcome.get(pollTimeoutMs, TimeUnit.MILLISECONDS)
        } catch (e: TimeoutException) {
            return BridgeResponse.json(400, """{"error":"timed out"}""", listOf("error" to "timed out"))
        } catch (e: ExecutionException) {
            Outcome("""{"error":"internal error"}""", "internal error")
        }
        sessions.remove(id)
        // vendor PinDistributor: the PIN session ends with the poll unless the batch asked to keep it
        if (!keepPin) forgetPin(id)
        val error = outcome.error ?: return BridgeResponse.json(200, outcome.payload)
        return BridgeResponse.json(400, outcome.payload, listOf("error" to headerSafe(error)))
    }

    /** Header values stay on one line and ASCII. */
    private fun headerSafe(text: String): String =
        text.map { if (it.code in 0x20..0x7E) it else ' ' }.joinToString("")

    /** Sessions nobody polled (the page went away) are dropped, so they cannot pile up. */
    private fun sweep() {
        val limit = clock() - SESSION_MAX_AGE_MS
        sessions.entries.removeIf { it.value.createdAt < limit }
    }

    // ------------------------------------------------------------------ PIN sessions (portal batches)

    private fun rememberPin(session: String, pin: CharArray, certificateSha1: String, origin: String?) =
        synchronized(pinSessions) {
            pinSessions.put(session, PinSession(pin.copyOf(), certificateSha1, origin, clock()))?.pin?.fill('\u0000')
        }

    /** A copy of the PIN the batch already signed with, or `null` (unknown, other origin, other card, expired). */
    private fun reusablePin(session: String, origin: String?, certificateSha1: String): CharArray? = synchronized(pinSessions) {
        val now = clock()
        pinSessions.entries.removeIf { (_, p) -> (now - p.lastUse >= PIN_SESSION_TTL_MS).also { if (it) p.pin.fill('\u0000') } }
        val entry = pinSessions[session] ?: return null
        if (entry.origin != origin || !entry.certificateSha1.equals(certificateSha1, ignoreCase = true)) return null
        entry.lastUse = now
        entry.pin.copyOf()
    }

    private fun forgetPin(session: String) = synchronized(pinSessions) {
        pinSessions.remove(session)?.pin?.fill('\u0000')
    }

    private fun queryItems(query: String?): Map<String, String> {
        if (query.isNullOrEmpty()) return emptyMap()
        return query.split('&').filter { it.isNotEmpty() }.associate { pair ->
            val eq = pair.indexOf('=')
            val key = if (eq < 0) pair else pair.substring(0, eq)
            val value = if (eq < 0) "" else pair.substring(eq + 1)
            URLDecoder.decode(key, "UTF-8") to URLDecoder.decode(value, "UTF-8")
        }
    }

    companion object {
        /** Consent + PIN entry take as long as the user does; the portal polls once. */
        const val POLL_TIMEOUT_MS = 10 * 60_000L
        const val PIN_SESSION_TTL_MS = 300_000L
        private const val SESSION_MAX_AGE_MS = 30 * 60_000L
        private val UNSUPPORTED_ROUTES = listOf("/sign/pdf", "/sign/file", "/verify/pdf")
    }
}
