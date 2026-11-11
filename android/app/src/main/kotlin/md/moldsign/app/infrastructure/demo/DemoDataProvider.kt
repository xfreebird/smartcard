package md.moldsign.app.infrastructure.demo

import android.net.Uri
import md.moldsign.app.application.PickedDocument
import md.moldsign.app.application.PreviewDataProvider
import md.moldsign.core.Document

/** Never opens a caller-supplied URI, even if a real document reaches the demo session. */
class DemoDataProvider : PreviewDataProvider {
    override fun inputs() = listOf("DEMO-contract.pdf", "DEMO-request.pdf").map(::sample)
    override fun verificationInput() = sample("DEMO-contract.pdf")
    override fun document(item: PickedDocument) = Document(item.name, DemoFixtures.samplePdf)
    override fun completedNames() = listOf("Application", "Invoice", "Agreement")
    override fun outputName(inputName: String): String {
        val name = inputName.removePrefix("DEMO-").substringBeforeLast('.')
        return "DEMO-$name-NOT-SIGNED.pdf"
    }
    override fun outputBytes() = DemoOutputRenderer.render()
    override fun protectionPreview(scenario: String): md.moldsign.app.application.ProtectionPreview? {
        if (!scenario.startsWith("protect-")) return null
        val decrypt = scenario.contains("decrypt")
        return md.moldsign.app.application.ProtectionPreview(
            sourceName = if (decrypt) "Contract.pdf.symmetric.p7m" else "Contract.pdf",
            completionSourceName = if (decrypt) "Contract.txt.symmetric.p7m" else "Contract.txt",
            decrypt = decrypt,
            completed = scenario.endsWith("complete"),
        )
    }
    override fun protectedOutputBytes(decrypt: Boolean): ByteArray {
        val password = "Example-only-2026".toCharArray()
        try {
            val encrypted = md.moldsign.core.protection.PasswordFileProtection.encrypt("Example document".toByteArray(), password)
            if (!decrypt) return encrypted
            return try { md.moldsign.core.protection.PasswordFileProtection.decrypt(encrypted, password) }
            finally { encrypted.fill(0) }
        } finally { password.fill('\u0000') }
    }
    override fun verificationPreview(name: String) = PickedDocument(
        Uri.parse("demo://capture/$name"), name, 39_142,
        if (name.endsWith(".xml")) "application/xml" else "application/pdf",
    )
    private fun sample(name: String) = PickedDocument(
        Uri.parse("demo://sample/$name"), name, DemoFixtures.samplePdf.size.toLong(), "application/pdf",
    )
}
