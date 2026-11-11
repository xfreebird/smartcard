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
    override fun verificationPreview(name: String) = PickedDocument(
        Uri.parse("demo://capture/$name"), name, 39_142,
        if (name.endsWith(".xml")) "application/xml" else "application/pdf",
    )
    private fun sample(name: String) = PickedDocument(
        Uri.parse("demo://sample/$name"), name, DemoFixtures.samplePdf.size.toLong(), "application/pdf",
    )
}
