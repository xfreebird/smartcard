package md.moldsign.app.nfc

/**
 * Who owns foreground reader mode, and when it may be released.
 *
 * Android dispatches every tag that appears while reader mode is off. The eID is an ISO-DEP card
 * without NDEF, so turning reader mode off while it is still in the RF field makes the system show
 * "No supported app for this NFC tag". A session therefore never disables reader mode once it has
 * seen a tag: the gate keeps it enabled and absorbs (never connects to) later discoveries until the
 * host activity pauses. On that release the last tag is ignored first, so the platform does not
 * dispatch it again while it stays in range. Without a discovered tag nothing is in the field and
 * reader mode is released as soon as the session ends.
 *
 * [open], [finished] and [paused] run on the main thread; [discovered] runs on a binder thread.
 * Platform calls are made outside the lock.
 */
internal class NfcReaderModeGate<H : Any, T : Any>(private val radio: Radio<H, T>) {
    interface Radio<H : Any, T : Any> {
        /** Foreground reader mode on [host]; every discovered tag goes to [onTag]. */
        fun enable(host: H, onTag: (T) -> Unit)
        fun disable(host: H)
        /** Asks the platform not to dispatch [tag] again until it has left the field. False if it is gone. */
        fun ignore(tag: T): Boolean
    }

    /** The session currently waiting for a card. */
    fun interface Route<T : Any> {
        fun deliver(tag: T)
    }

    private val lock = Any()
    private var readerHost: H? = null
    private var route: Route<T>? = null
    private var heldTag: T? = null

    /** Reader mode is on (waiting for a card, or absorbing one that may still be in the field). */
    val active: Boolean get() = synchronized(lock) { readerHost != null }

    /** A card seen by reader mode has not been released to the platform yet. */
    val holdingTag: Boolean get() = synchronized(lock) { heldTag != null }

    /**
     * Routes the next discovered tag to [route], enabling reader mode on [host] if needed. A card held
     * from the previous session is ignored so the platform presents it again to this one (or reports
     * that it has left). Rethrows a platform failure after restoring the released state.
     */
    fun open(host: H, route: Route<T>) {
        val previousHost: H?
        val held: T?
        synchronized(lock) {
            previousHost = readerHost
            held = heldTag
            heldTag = null
            this.route = route
            readerHost = host
        }
        if (previousHost === host) {
            held?.let(::ignoreQuietly)
            return
        }
        if (previousHost != null) release(previousHost, held)
        try {
            radio.enable(host, ::discovered)
        } catch (error: Exception) {
            synchronized(lock) {
                if (readerHost === host) readerHost = null
                if (this.route === route) this.route = null
            }
            throw error
        }
    }

    /** Binder thread: every tag is remembered while reader mode is on; only a waiting session receives it. */
    fun discovered(tag: T) {
        val target = synchronized(lock) {
            if (readerHost == null) return
            heldTag = tag
            route
        }
        target?.deliver(tag)
    }

    /**
     * A session ended on any path. Returns true when reader mode stays on because a card may still be in
     * the field; false when it was released (or another session now owns it).
     */
    fun finished(route: Route<T>): Boolean {
        val host: H
        synchronized(lock) {
            if (this.route === route) this.route = null
            if (this.route != null) return false
            host = readerHost ?: return false
            if (heldTag != null) return true
            readerHost = null
        }
        disableQuietly(host)
        return false
    }

    /** Reader mode cannot outlive the foreground: release it, ignoring the last card first. */
    fun paused(host: H) {
        val held: T?
        synchronized(lock) {
            if (readerHost !== host) return
            readerHost = null
            route = null
            held = heldTag
            heldTag = null
        }
        release(host, held)
    }

    private fun release(host: H, held: T?) {
        held?.let(::ignoreQuietly)
        disableQuietly(host)
    }

    private fun ignoreQuietly(tag: T) { runCatching { radio.ignore(tag) } }
    private fun disableQuietly(host: H) { runCatching { radio.disable(host) } }
}
