package md.moldsign.app.infrastructure

import md.moldsign.app.application.DocumentAccess
import md.moldsign.app.application.DocumentDataProvider
import md.moldsign.app.application.PickedDocument
import md.moldsign.core.Document

class LiveDocumentDataProvider(private val access: DocumentAccess) : DocumentDataProvider {
    override fun document(item: PickedDocument) = Document(item.name, access.readBytes(item.uri))
}
