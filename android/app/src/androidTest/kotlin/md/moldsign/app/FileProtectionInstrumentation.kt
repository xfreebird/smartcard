package md.moldsign.app

import android.app.Activity
import android.app.Instrumentation
import android.os.Bundle

/** Dispatches native suites; fixtures and scenario behavior belong to their own providers. */
class FileProtectionInstrumentation : Instrumentation() {
    private var phase: String? = null
    private var suite: String? = null

    override fun onCreate(arguments: Bundle?) {
        super.onCreate(arguments)
        phase = arguments?.getString("phase")
        suite = arguments?.getString("suite")
        start()
    }

    override fun onStart() {
        val result = Bundle()
        try {
            require(suite == null || suite == "journeys" || suite == "protection" || suite == "browser-locale" || suite == "nfc-preparation" || suite == "saved-identities" || suite == "browser-authentication") { "Unknown integration suite: $suite" }
            require(suite == null || phase == null) { "A journey suite cannot select a persistence phase" }
            val message = when {
                suite == "browser-authentication" -> BrowserAuthenticationUIIntegration(this).run()
                suite == "saved-identities" -> SavedIdentityRemovalIntegration(this).run()
                suite == "nfc-preparation" -> NfcPreparationIntegration(this).run()
                suite == "journeys" -> JourneyAutomation(this).run()
                suite == "browser-locale" -> BrowserLocaleIntegration(this).run()
                phase != null -> ProtectionPersistenceIntegration(targetContext).run(requireNotNull(phase))
                else -> ProtectionStorageIntegration(targetContext).run()
            }
            result.putString("result", message)
            finish(Activity.RESULT_OK, result)
        } catch (error: Throwable) {
            result.putString("result", "FAIL: ${error.javaClass.simpleName}: ${error.message}")
            result.putString("stack", error.stackTraceToString())
            finish(Activity.RESULT_CANCELED, result)
        }
    }
}
