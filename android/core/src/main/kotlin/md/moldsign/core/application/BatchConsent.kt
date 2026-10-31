package md.moldsign.core

/** One authorization for an immutable document batch, scoped to one certificate and requester. */
class BatchConsent(
    private val inner: Consent,
    documentNames: List<String>? = null,
    private val batchFormat: String? = null,
    private val expectedCertificateSha1: String? = null,
    private val expectedRequester: String? = null,
    allowedFormats: Set<String>? = null,
) : Consent, AutoCloseable {
    private val documents = documentNames?.toList()
    private val formats = allowedFormats?.toSet()
    private var certificateSha1: String? = null
    private var pin: CharArray? = null
    private var closed = false

    @Synchronized
    override fun obtain(request: ConsentRequest): ConsentResult {
        if (closed) return ConsentResult.Cancelled
        val certificate = request.certificate.sha1Hex
        if (request.requester != expectedRequester ||
            (formats != null && request.format !in formats) ||
            (expectedCertificateSha1 != null && certificate != expectedCertificateSha1) ||
            (certificateSha1 != null && certificate != certificateSha1) ||
            (documents != null && !documents.containsAll(request.documentNames))) {
            close()
            return ConsentResult.Cancelled
        }
        pin?.let { return ConsentResult.Pin(it.copyOf()) }
        val answer = try {
            inner.obtain(request.copy(documentNames = documents ?: request.documentNames, format = batchFormat ?: request.format))
        } catch (failure: Throwable) {
            close()
            throw failure
        }
        if (answer is ConsentResult.Pin) {
            certificateSha1 = certificate
            pin = answer.pin.copyOf()
        } else close()
        return answer
    }

    @Synchronized
    override fun close() {
        pin?.fill('\u0000')
        pin = null
        certificateSha1 = null
        closed = true
    }
}
