package md.moldsign.app

import md.moldsign.app.application.AppContainer

import android.app.Application
import android.content.Context
import android.content.Intent
import md.moldsign.app.bridge.BridgeService

/** Android composition root; feature coordination lives in application/AppContainer. */
class MoldSignApp : Application() {
    lateinit var container: AppContainer
        private set
    val demoModeEnabled: Boolean get() = getSharedPreferences("settings", Context.MODE_PRIVATE).getBoolean("demo_mode", false)

    fun changeDemoMode(enabled: Boolean): Boolean {
        if (container.busy.value || container.consentBroker.pending.value != null || container.stampBroker.pending.value != null) return false
        if (!getSharedPreferences("settings", Context.MODE_PRIVATE).edit().putBoolean("demo_mode", enabled).commit()) return false
        stopService(Intent(this, BridgeService::class.java))
        container.stop()
        container = AppContainer(this, userDemoMode = enabled)
        container.start()
        return true
    }

    override fun onCreate() {
        super.onCreate()
        container = AppContainer(this, userDemoMode = demoModeEnabled)
        container.start()
    }
}
