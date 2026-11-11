package md.moldsign.app

import android.net.Uri
import kotlinx.coroutines.CancellationException
import md.moldsign.app.application.DocumentOutputStore
import md.moldsign.app.application.SignDocuments
import md.moldsign.app.application.SignItem
import md.moldsign.app.infrastructure.demo.DemoDataProvider
import md.moldsign.app.infrastructure.demo.DemoSigningService
import md.moldsign.core.*
import java.io.IOException

/** Integrates the production batch workflow with replaceable data, signing and persistence ports. */
internal object SigningWorkflowIntegration {
    fun run(): List<String> {
        val data = DemoDataProvider()
        val inputs = data.inputs().map { SignItem(it) }
        check(inputs.size >= 2)
        val results = mutableListOf<String>()
        for ((name, failure, recoverable) in listOf(
            Triple("format", CardError.Format("fixture"), true),
            Triple("network", CardError.Network("fixture"), true),
            Triple("wrong-pin", CardError.WrongPin(1), false),
            Triple("card-changed", CardError.CardChanged("expected", "actual"), false),
            Triple("cancel", CancellationException("fixture"), false),
        )) {
            val demo = DemoSigningService()
            var calls = 0
            val signing = object : SigningService by demo {
                override fun sign(input: Document, format: SignFormat, consent: Consent, requester: String?,
                                  reader: String?, expectedCertificateSha1: String?, placement: PdfStampPlacement?): SignResult {
                    check(reader == "selected-reader" && expectedCertificateSha1 == "selected-certificate")
                    if (++calls == 1) throw failure
                    return demo.sign(input, format, consent, requester, reader, expectedCertificateSha1, placement)
                }
            }
            var saves = 0
            val events = mutableListOf<SignDocuments.Event>()
            val workflow = SignDocuments(signing, data, DocumentOutputStore { _, _, _ ->
                saves++; Uri.parse("demo://output/$saves")
            })
            val thrown = runCatching { workflow.execute(inputs, "selected-reader", "selected-certificate",
                Consent { error("Unexpected PIN request") }, events::add) }.exceptionOrNull()
            if (recoverable) {
                check(thrown == null && calls == inputs.size && saves == inputs.size - 1)
                check(events.count { it is SignDocuments.Event.Failed } == 1)
            } else {
                check(thrown === failure && calls == 1 && saves == 0)
                if (failure is CancellationException) check(events.none { it is SignDocuments.Event.Failed })
            }
            results += "batch-$name:pass"
        }
        var writes = 0
        val events = mutableListOf<SignDocuments.Event>()
        SignDocuments(DemoSigningService(), data, DocumentOutputStore { _, _, _ ->
            if (++writes == 1) throw IOException("Destination unavailable")
            Uri.parse("demo://output/$writes")
        }).execute(inputs, "reader", "certificate", Consent { error("Unexpected PIN request") }, events::add)
        check(writes == inputs.size && events.count { it is SignDocuments.Event.Failed } == 1)
        check(events.count { it is SignDocuments.Event.Saved } == inputs.size - 1)
        results += "batch-output-failure:pass"

        val consumerFailure = IllegalStateException("Presentation failed")
        var writesBeforeConsumerFailure = 0
        val consumerEvents = mutableListOf<SignDocuments.Event>()
        val thrown = runCatching {
            SignDocuments(DemoSigningService(), data, DocumentOutputStore { _, _, _ ->
                writesBeforeConsumerFailure++; Uri.parse("demo://output/1")
            }).execute(inputs, "reader", "certificate", Consent { error("Unexpected PIN request") }) {
                consumerEvents += it
                if (it is SignDocuments.Event.Saved) throw consumerFailure
            }
        }.exceptionOrNull()
        check(thrown === consumerFailure && writesBeforeConsumerFailure == 1)
        check(consumerEvents.none { it is SignDocuments.Event.Failed })
        results += "batch-consumer-failure:pass"
        return results
    }
}
