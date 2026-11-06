package md.moldsign.app

import md.moldsign.app.application.AppContainer
import md.moldsign.app.presentation.MainViewModel

import android.content.Intent

/** Release builds have no demo mode: the fake cards live only in the debug source set (src/debug). */
internal object DemoMode {
    const val supportsResultPreview = false
    const val stampPreview = false
    @Suppress("UNUSED_PARAMETER")
    fun screenshotCapture(intent: Intent?): Boolean = false
    @Suppress("UNUSED_PARAMETER")
    fun apply(container: AppContainer, intent: Intent?, viewModel: MainViewModel) = Unit
}
