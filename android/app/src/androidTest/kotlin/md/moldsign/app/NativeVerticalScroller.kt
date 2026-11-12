package md.moldsign.app

import android.app.Instrumentation
import android.graphics.Rect
import android.os.SystemClock
import android.view.InputDevice
import android.view.MotionEvent
import android.view.accessibility.AccessibilityNodeInfo

/** Overlapping vertical drags keep controls reachable between fixed headers and transient snackbars. */
internal class NativeVerticalScroller(private val runner: Instrumentation) {
    fun scroll(target: AccessibilityNodeInfo, down: Boolean) {
        val bounds = Rect().also(target::getBoundsInScreen)
        check(bounds.width() > 0 && bounds.height() > 0) { "Scrollable content has no visible bounds" }
        val x = bounds.exactCenterX()
        // Use the upper/middle portion, clear of bottom navigation, snackbars and floating actions.
        val upper = bounds.top + bounds.height() * 0.25f
        val lower = bounds.top + bounds.height() * 0.60f
        val start = if (down) lower else upper
        val end = if (down) upper else lower
        val downTime = SystemClock.uptimeMillis()
        fun send(action: Int, y: Float) {
            val event = MotionEvent.obtain(downTime, SystemClock.uptimeMillis(), action, x, y, 0)
            event.source = InputDevice.SOURCE_TOUCHSCREEN
            try { check(runner.uiAutomation.injectInputEvent(event, true)) { "Vertical drag event was rejected" } }
            finally { event.recycle() }
        }
        var finished = false
        try {
            send(MotionEvent.ACTION_DOWN, start)
            for (step in 1..20) {
                SystemClock.sleep(20)
                send(MotionEvent.ACTION_MOVE, start + (end - start) * step / 20)
            }
            // End at rest so inertia cannot skip the next control after this bounded drag.
            SystemClock.sleep(120)
            send(MotionEvent.ACTION_MOVE, end)
            send(MotionEvent.ACTION_UP, end)
            finished = true
        } finally {
            if (!finished) runCatching { send(MotionEvent.ACTION_CANCEL, end) }
        }
    }
}
