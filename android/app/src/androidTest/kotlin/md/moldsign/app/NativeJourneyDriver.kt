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
        .mapNotNull { it.text?.toString() ?: it.contentDescription?.toString() }.take(40).joinToString(" | ")
    fun text(value: String) = all(runner.uiAutomation.rootInActiveWindow).firstOrNull {
        it.isVisibleToUser && (it.text?.toString()?.lines()?.contains(value) == true || it.contentDescription?.toString()?.lines()?.contains(value) == true)
    }
    fun id(value: String) = all(runner.uiAutomation.rootInActiveWindow).firstOrNull {
        it.isVisibleToUser && it.viewIdResourceName == value
    }
    private fun tryClick(node: AccessibilityNodeInfo?): Boolean {
        var target: AccessibilityNodeInfo? = node
        while (target != null) {
            if (target.isClickable) return target.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            target = target.parent
        }
        return false
    }
    // A node can be replaced between lookup and activation during a Compose transition.
    // Retry only rejected actions, re-querying the current tree each time.
    fun clickText(value: String) { await("click $value") { tryClick(text(value)) } }
    fun clickId(value: String) { reveal(value) { id(value) }; await("click $value") { tryClick(id(value)) } }
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
        error("Missing control after scrolling: $description")
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
