package md.moldsign.app

import android.app.Instrumentation
import android.os.Build
import android.view.accessibility.AccessibilityNodeInfo

/** Always re-query after an action; Compose replaces accessibility nodes as state changes. */
internal class NativeJourneyDriver(private val runner: Instrumentation) {
    private fun currentNodes(): Sequence<AccessibilityNodeInfo> {
        // Fetching a new root can still return cached children after Compose changes a tag/label.
        if (Build.VERSION.SDK_INT >= 34) runner.uiAutomation.clearCache()
        return all(runner.uiAutomation.rootInActiveWindow)
    }
    private fun all(node: AccessibilityNodeInfo?): Sequence<AccessibilityNodeInfo> = sequence {
        if (node == null) return@sequence
        if (Build.VERSION.SDK_INT < 34 && !node.refresh()) return@sequence
        yield(node)
        for (index in 0 until node.childCount) yieldAll(all(node.getChild(index)))
    }
    fun describe(): String = currentNodes().filter { !it.isPassword }
        .mapNotNull { node ->
            val text = node.text?.toString() ?: node.contentDescription?.toString() ?: node.viewIdResourceName ?: return@mapNotNull null
            "$text [id=${node.viewIdResourceName}, visible=${node.isVisibleToUser}, clickable=${node.isClickable}, enabled=${node.isEnabled}]"
        }.take(40).joinToString(" | ")
    fun text(value: String) = currentNodes().firstOrNull {
        it.isVisibleToUser && (it.text?.toString()?.lines()?.contains(value) == true || it.contentDescription?.toString()?.lines()?.contains(value) == true)
    }
    fun id(value: String) = currentNodes().firstOrNull {
        it.isVisibleToUser && it.viewIdResourceName == value
    }
    private fun clickTarget(node: AccessibilityNodeInfo?): AccessibilityNodeInfo? {
        var target = node
        while (target != null) {
            if (!target.isEnabled) return null
            if (target.isClickable) return target
            target = target.parent
        }
        return null
    }
    private fun performClick(description: String, find: () -> AccessibilityNodeInfo?) {
        settleAccessibility()
        var target: AccessibilityNodeInfo? = null
        await("clickable $description") { target = find(); target != null }
        // Retry lookup, never an already dispatched action: a timed-out click can arrive late.
        val acknowledged = checkNotNull(target).performAction(AccessibilityNodeInfo.ACTION_CLICK)
        android.util.Log.i("MoldSignUiTest", "Click $description: acknowledged=$acknowledged")
        runner.waitForIdleSync()
    }
    private fun settleAccessibility() {
        runner.waitForIdleSync()
        // Re-query after Compose's scroll/layout events stop; nodes observed mid-animation can
        // leave the viewport before ACTION_CLICK reaches the main thread.
        runner.uiAutomation.waitForIdle(200, 5_000)
    }
    // Callers verify the resulting screen/domain state; the IPC acknowledgement is not completion.
    fun clickText(value: String) { performClick(value) { clickTarget(text(value)) } }
    // IDs identify the action owner. Never redirect a disabled action to a clickable ancestor.
    private fun clickableId(value: String) = id(value)?.takeIf { it.isClickable && it.isEnabled }
    fun clickId(value: String) {
        reveal(value) { id(value) }
        performClick(value) { clickableId(value) }
    }
    fun clickTextAndAwait(value: String, description: String, condition: () -> Boolean) {
        clickText(value)
        await(description, condition)
    }
    fun clickIdAndAwait(value: String, description: String, condition: () -> Boolean) {
        reveal(value) { id(value) }
        // A timed-out accessibility action can still reach the main thread later.
        // Dispatch a toggle once and observe its result instead of queuing another click.
        performClick(value) { clickableId(value) }
        await(description, condition)
    }
    fun revealUp(description: String, find: () -> AccessibilityNodeInfo?) =
        reveal(description, listOf(AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD), find)
    fun reveal(description: String, find: () -> AccessibilityNodeInfo?) =
        reveal(description, listOf(AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD, AccessibilityNodeInfo.ACTION_SCROLL_FORWARD), find)
    fun scrollToBottom() {
        repeat(20) {
            val moved = currentNodes()
                .filter { it.isScrollable && it.isVisibleToUser }
                .map { it.performAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD) }.toList().any { it }
            if (!moved) return
            settleAccessibility()
        }
        error("Scroll did not reach the bottom; ${describe()}")
    }
    private fun reveal(description: String, directions: List<Int>, find: () -> AccessibilityNodeInfo?) {
        await("application window") { runner.uiAutomation.rootInActiveWindow != null }
        // A completed operation can move the viewport below a preceding action. Search back to
        // the beginning before scanning forward, instead of assuming every target is below us.
        for (direction in directions) {
            repeat(20) {
                if (find() != null) return
                currentNodes().filter { it.isScrollable && it.isVisibleToUser }
                    .forEach { it.performAction(direction) }
                settleAccessibility()
            }
        }
        if (find() != null) return
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
