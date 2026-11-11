package md.moldsign.app.application

import md.moldsign.core.Document

/** Document bytes are supplied independently of presentation and signing. */
interface DocumentDataProvider {
    fun document(item: PickedDocument): Document
}
