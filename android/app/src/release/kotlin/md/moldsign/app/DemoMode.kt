package md.moldsign.app

import android.content.Intent

/** Release builds have no demo mode: the fake cards live only in the debug source set (src/debug). */
internal object DemoMode {
    @Suppress("UNUSED_PARAMETER")
    fun apply(container: AppContainer, intent: Intent?) = Unit
}
