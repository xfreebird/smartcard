package md.moldsign.app.infrastructure.demo

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import md.moldsign.app.application.ReaderGateway
import md.moldsign.core.*
import java.util.Date

/** Happy-flow preview. It ignores input bytes and returns visibly unsigned sample content only. */
internal class DemoSigningService : SigningService {
    private val steps = MutableStateFlow(SigningStep.Idle)
    override val progress = steps.asStateFlow()
    override val readerState = MutableStateFlow<ReaderState>(ReaderState.CardPresent("Demo reader 1")).asStateFlow()
    override fun certificate(reader: String?) = DemoFixtures.certificates[if (reader == "preview-2") 1 else 0]
    override fun signPdf(input: Document, consent: Consent, requester: String?, reader: String?, expectedCertificateSha1: String?) = preview(reader, "DEMO")
    override fun signXades(files: List<Document>, level: XadesLevel, packaging: XadesPackaging, consent: Consent, requester: String?, reader: String?, expectedCertificateSha1: String?, digest: XadesDigest) = preview(reader, "DEMO")
    override fun signDigestInfo(digestInfo: ByteArray, documentName: String, consent: Consent, requester: String?, reader: String?, expectedCertificateSha1: String?): RawSignature = throw CardError.NoReader()
    private fun preview(reader: String?, format: String): SignResult {
        for (step in listOf(SigningStep.Connecting, SigningStep.Authenticating, SigningStep.Signing, SigningStep.Done)) {
            steps.value = step
            Thread.sleep(160)
        }
        return SignResult(DemoFixtures.samplePdf.copyOf(), certificate(reader), format)
    }
    override fun verify(file: Document, detachedDocuments: List<Document>) = listOf(
        ValidationReport("DEMO ONLY", Date(), Date(), "DEMO", true, true, true,
            details = listOf("Fictional preview. No signature or real document was verified.")),
    )
}
