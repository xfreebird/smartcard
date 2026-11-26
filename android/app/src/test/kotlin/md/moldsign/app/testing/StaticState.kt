package md.moldsign.app.testing

import androidx.core.content.FileProvider
import androidx.lifecycle.ViewModelProvider

/**
 * Robolectric gives each test a new Application and data directory but keeps library statics: FileProvider
 * caches its path roots per authority, and AndroidViewModelFactory keeps the first Application it saw.
 */
fun resetStaticAndroidState() {
    val cache = FileProvider::class.java.getDeclaredField("sCache").apply { isAccessible = true }.get(null) as MutableMap<*, *>
    synchronized(cache) { cache.clear() }
    ViewModelProvider.AndroidViewModelFactory::class.java.getDeclaredField("_instance").apply { isAccessible = true }.set(null, null)
}
