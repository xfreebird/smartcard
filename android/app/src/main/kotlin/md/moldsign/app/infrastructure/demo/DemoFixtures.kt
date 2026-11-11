package md.moldsign.app.infrastructure.demo

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import md.moldsign.app.application.ReaderGateway
import md.moldsign.core.*
import java.util.Date

/** Fictional public display values: no key, certificate DER, physical transport or PIN exists. */
internal object DemoFixtures {
    val readers = listOf(
        ReaderSlot("preview-1", "Demo reader 1", ReaderSlot.State.Card, 1),
        ReaderSlot("preview-2", "Demo reader 2", ReaderSlot.State.Card, 1),
    )
    val certificates = listOf("POPESCU" to "ION", "MÎNDRU" to "ANA-MARIA").mapIndexed { index, (surname, given) ->
        CertificateSummary("$surname $given", "CN=Fictional Demo", "CN=DEMO ONLY", "DEMO ONLY",
            Date(1735689600000L), Date(1893456000000L), "DEMO${index + 1}",
            (index + 1).toString().repeat(40), surname, given, der = null)
    }
    val samplePdf = "%PDF-1.7\n% DEMO ONLY - NOT SIGNED\n%%EOF\n".toByteArray()
}
