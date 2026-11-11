package md.moldsign.app.application

/** Fictional inputs and output bytes for an isolated demonstration session. */
interface PreviewDataProvider : DocumentDataProvider {
    fun inputs(): List<PickedDocument>
    fun verificationInput(): PickedDocument
    fun completedNames(): List<String>
    fun outputName(inputName: String): String
    fun outputBytes(): ByteArray
    fun protectionPreview(scenario: String): ProtectionPreview?
    fun protectedOutputBytes(decrypt: Boolean): ByteArray
    fun verificationPreview(name: String): PickedDocument
}
