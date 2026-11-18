package md.moldsign.app

import android.app.Instrumentation
import android.os.Build
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import md.moldsign.app.application.AppContainer
import md.moldsign.app.infrastructure.demo.DemoReaderGateway
import md.moldsign.app.infrastructure.demo.DemoSigningService
import md.moldsign.app.presentation.MainViewModel
import md.moldsign.core.CertificateSummary
import md.moldsign.core.SigningService
import java.util.concurrent.atomic.AtomicInteger

/** Use a clean, separate test install. Both reader slots return the same public test identity. */
internal class SavedIdentityRemovalIntegration(private val runner: Instrumentation) {
    fun run(): String {
        val app = runner.targetContext.applicationContext as MoldSignApp
        check(BuildConfig.DEBUG && (app.packageName.endsWith(".nfctest") || Build.HARDWARE in setOf("ranchu", "goldfish"))) {
            "Use the separate NFC test app or a dedicated Android emulator"
        }
        val der = requireNotNull(javaClass.getResourceAsStream("/md/moldsign/core/mdqsign.der")).use { it.readBytes() }
        val card = CertificateSummary.parse(der)
        val reads = AtomicInteger()
        val container = AppContainer(app, readerFactory = { _, _ -> DemoReaderGateway() },
            signingFactory = { object : SigningService by DemoSigningService() {
                override fun certificate(reader: String?): CertificateSummary {
                    reads.incrementAndGet()
                    return card
                }
            } })
        check(container.savedCardIdentities.read().none { it.sha1Hex == card.sha1Hex })
        check(runBlocking { container.pinVault.accounts.first() }.none { it == card.sha1Hex })
        val models = mutableListOf<MainViewModel>()
        fun model(): MainViewModel {
            lateinit var vm: MainViewModel
            runner.runOnMainSync { vm = MainViewModel(app, container = container); models += vm }
            return vm
        }
        try {
            container.savedCardIdentities.save(card)
            container.start()
            val vm = model()
            runBlocking { withTimeout(10_000) { container.wallet.first { it.selectedCard?.certificate?.sha1Hex == card.sha1Hex } } }
            runner.runOnMainSync {
                vm.selectNfcCard(card)
                container.browserNfc.seed(card)
                check(vm.knownCards.value.any { it.sha1Hex == card.sha1Hex })
                vm.forgetCard(card.sha1Hex)
            }
            runBlocking { withTimeout(10_000) { vm.working.first { !it } } }
            check(vm.nfcIdentity.value == null && container.browserNfc.certificate.value?.sha1Hex != card.sha1Hex)
            check(vm.knownCards.value.none { it.sha1Hex == card.sha1Hex } && container.savedCardIdentities.read().none { it.sha1Hex == card.sha1Hex })
            val before = reads.get()
            container.rereadCards()
            runBlocking { withTimeout(10_000) { container.wallet.first { reads.get() > before && it.selectedCard?.certificate?.sha1Hex == card.sha1Hex } } }
            check(vm.knownCards.value.none { it.sha1Hex == card.sha1Hex })
            val restored = model()
            check(restored.knownCards.value.none { it.sha1Hex == card.sha1Hex })
            return "PASS: saved-identities. Forgetting a card without a PIN cleared both NFC selections and persisted metadata. Reader rediscovery and a fresh model did not restore it."
        } finally {
            models.forEach { it.viewModelScope.cancel() }
            container.savedCardIdentities.delete(card.sha1Hex)
            container.stop()
        }
    }
}
