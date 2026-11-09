package md.moldsign.app

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper

/** Dialogs and locale-scoped Compose contexts can wrap the owning activity. */
fun Context.hostActivity(): Activity? {
    var current = this
    while (current is ContextWrapper) {
        if (current is Activity) return current
        val base = current.baseContext
        if (base === current) return null
        current = base
    }
    return current as? Activity
}
