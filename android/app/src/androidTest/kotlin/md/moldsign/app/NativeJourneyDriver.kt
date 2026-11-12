package md.moldsign.app

import android.app.Instrumentation
import android.view.accessibility.AccessibilityNodeInfo

/** Always re-query after an action; Compose replaces accessibility nodes as state changes. */
internal class NativeJourneyDriver(private val runner: Instrumentation) {
    private fun all(node: AccessibilityNodeInfo?): Sequence<AccessibilityNodeInfo> = sequence {
        if (node == null) return@sequence
        yield(node)
        for (index in 0 until node.childCount) yieldAll(all(node.getChild(index)))
    }
    fun describe(): String = all(runner.uiAutomation.rootInActiveWindow).filter { !it.isPassword }
        .mapNotNull { node ->
            val text = node.text?.toString() ?: node.contentDescription?.toString() ?: node.viewIdResourceName ?: return@mapNotNull null
            "$text [id=${node.viewIdResourceName}, visible=${node.isVisibleToUser}, clickable=${node.isClickable}, enabled=${node.isEnabled}]"
        }.take(40).joinToString(" | ")
    fun text(value: String) = all(runner.uiAutomation.rootInActiveWindow).firstOrNull {
        it.isVisibleToUser && (it.text?.toString()?.lines()?.contains(value) == true || it.contentDescription?.toString()?.lines()?.contains(value) == true)
    }
    fun id(value: String) = all(runner.uiAutomation.rootInActiveWindow).firstOrNull {
        it.isVisibleToUser && it.viewIdResourceName == value
    }
    private fun clickTarget(node: AccessibilityNodeInfo?): AccessibilityNodeInfo? {
        var target = node
        while (target != null) {
            if (target.isClickable && target.isEnabled) return target
            target = target.parent
        }
        return null
    }
    private fun performClick(description: String, find: () -> AccessibilityNodeInfo?) {
        var target: AccessibilityNodeInfo? = null
        await("clickable $description") { target = clickTarget(find()); target != null }
        // Retry lookup, never an already dispatched action: a timed-out click can arrive late.
        checkNotNull(target).performAction(AccessibilityNodeInfo.ACTION_CLICK)
        runner.waitForIdleSync()
    }
    // Callers verify the resulting screen/domain state; the IPC acknowledgement is not completion.
    fun clickText(value: String) { performClick(value) { text(value) } }
    fun clickId(value: String) {
        reveal(value) { id(value) }
        performClick(value) { id(value) }
    }
    fun clickTextAndAwait(value: String, description: String, condition: () -> Boolean) {
        clickText(value)
        await(description, condition)
    }
    fun clickIdAndAwait(value: String, description: String, condition: () -> Boolean) {
        reveal(value) { id(value) }
        // A timed-out accessibility action can still reach the main thread later.
        // Dispatch a toggle once and observe its result instead of queuing another click.
        performClick(value) { id(value) }
        await(description, condition)
    }
    fun revealUp(description: String, find: () -> AccessibilityNodeInfo?) = reveal(description, AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD, find)
    fun reveal(description: String, find: () -> AccessibilityNodeInfo?) = reveal(description, AccessibilityNodeInfo.ACTION_SCROLL_FORWARD, find)
    private fun reveal(description: String, direction: Int, find: () -> AccessibilityNodeInfo?) {
        await("application window") { runner.uiAutomation.rootInActiveWindow != null }
        repeat(20) {
            if (find() != null) return
            all(runner.uiAutomation.rootInActiveWindow).filter { it.isScrollable && it.isVisibleToUser }
                .forEach { it.performAction(direction) }
            Thread.sleep(150)
        }
        error("Missing control after scrolling: $description; ${describe()}")
    }
    fun await(description: String, condition: () -> Boolean) {
        val deadline = android.os.SystemClock.uptimeMillis() + 15_000
        while (android.os.SystemClock.uptimeMillis() < deadline) {
            if (condition()) return
            Thread.sleep(100)
        }
        error("Timed out: $description; ${describe()}")
    }
}
