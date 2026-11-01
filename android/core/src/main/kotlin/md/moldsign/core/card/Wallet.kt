package md.moldsign.core

/**
 * Several readers / cards (docs/09 §3.1b, docs/10 §0.2 card wallet, PLAN UX-01/UX-02).
 *
 * Pure state, no platform types: the platform monitor (Android `UsbReaderMonitor`) reports [ReaderSlot]s,
 * the app keeps a [WalletState] and reconciles it with every snapshot. Same rules as the Apple
 * `AppModel.apply`: a card is identified by (reader, generation); a new generation drops what was known
 * about that reader's card and its certificate is read again (once per insertion, never in a loop: the
 * 6985 trap, R-07).
 */
data class ReaderSlot(
    /** Stable while the reader stays attached (Android: the USB device path). The key for [TransportProvider.open]. */
    val id: String,
    /** Display name (USB product name; " #2" suffix when two identical readers are attached). */
    val name: String,
    val state: State,
    /** Card generation from [CardGenerations]; 0 while there is no card. */
    val generation: Long = 0,
) {
    enum class State {
        /** Attached, but the user has not granted USB access yet (AND-03). */
        PermissionRequired,
        Empty,
        Card,

        /** The reader itself fails (CCID errors); the message is in [ReaderSlot] consumers' logs only. */
        Error,
    }
}

/**
 * Generation counter per reader (docs/09 §3.1b "Card-change detection"): a reader gets a new, never reused
 * value whenever a card is present after it was absent (or after the reader was attached with a card).
 * Thread-safe.
 */
class CardGenerations {
    private var next = 1L
    private val current = HashMap<String, Long>()

    /** Reports the presence seen in [readerId]; returns the card's generation, or 0 without a card. */
    @Synchronized
    fun observe(readerId: String, cardPresent: Boolean): Long {
        if (!cardPresent) {
            current.remove(readerId)
            return 0
        }
        return current.getOrPut(readerId) { next++ }
    }

    /** The reader was detached: a later re-attach starts a new generation. */
    @Synchronized
    fun forget(readerId: String) {
        current.remove(readerId)
    }
}

/** One inserted card, as the wallet draws it. */
data class WalletCard(
    val readerId: String,
    val readerName: String,
    val generation: Long,
    /** PIN-less certificate read; `null` while reading or after a failure. */
    val certificate: CertificateSummary? = null,
    /** Why the certificate read failed (the red error card). */
    val problem: Throwable? = null,
) {
    val isReady: Boolean get() = certificate != null && problem == null
    val isReading: Boolean get() = certificate == null && problem == null
}

/** The status light of docs/10 §0.1 (tray / notification / top app bar). Color is never the only signal. */
enum class StatusLight {
    /** green: the selected card is read and ready */
    Ready,

    /** amber: reader(s) connected, no card, card being read, or USB access still to grant */
    Reader,

    /** blue: signing / bridge request in progress */
    Busy,

    /** red: the card cannot be read, or the reader fails */
    Error,

    /** no dot: nothing connected */
    Idle,
}

/**
 * Tray / menu bar / Android bridge notification (docs/10 §0.2b, UX-11): two states only. [connected] when at
 * least one card is inserted and not in error (reading, ready or signing); [card] is the one to name (the
 * selected card when it qualifies). Otherwise gray, with the selected card's [problem] or a [readerError] as
 * the one-liner when there is one.
 */
data class TrayStatus(
    val connected: Boolean,
    val card: WalletCard? = null,
    val problem: Throwable? = null,
    val readerError: Boolean = false,
)

data class WalletState(
    val readers: List<ReaderSlot> = emptyList(),
    val cards: List<WalletCard> = emptyList(),
    /** The user's pick; falls back to the first card when that reader is gone. */
    val selectedReaderId: String? = null,
) {
    /** The card the UI signs with: the user's pick, else the first inserted one. */
    val selectedCard: WalletCard? get() = cards.firstOrNull { it.readerId == selectedReaderId } ?: cards.firstOrNull()

    val readyCards: List<WalletCard> get() = cards.filter { it.isReady }

    /** Result of [reconcile] / [forgetCertificates]: the new state and the cards whose certificate must be read. */
    data class Update(val state: WalletState, val toRead: List<WalletCard>)

    /**
     * Applies a monitor snapshot: a reader that still holds the same generation keeps its card (and certificate);
     * a new card or a new generation (removed + re-inserted, or swapped) starts fresh and is returned in
     * [Update.toRead]. Cards of readers that are gone or empty disappear.
     */
    fun reconcile(snapshot: List<ReaderSlot>): Update {
        val next = ArrayList<WalletCard>()
        val toRead = ArrayList<WalletCard>()
        for (slot in snapshot) {
            if (slot.state != ReaderSlot.State.Card) continue
            val known = cards.firstOrNull { it.readerId == slot.id }
            if (known != null && known.generation == slot.generation) {
                next += known.copy(readerName = slot.name)
            } else {
                val fresh = WalletCard(slot.id, slot.name, slot.generation)
                next += fresh
                toRead += fresh
            }
        }
        // Keep the user's selection while its reader is temporarily absent. selectedCard falls back
        // to the first available card, and the preferred reader becomes selected again on return.
        return Update(WalletState(snapshot, next, selectedReaderId ?: next.firstOrNull()?.readerId), toRead)
    }

    /** Stores a certificate read; ignored when that card was removed or replaced meanwhile. */
    fun withCertificate(card: WalletCard, summary: CertificateSummary): WalletState =
        replace(card) { it.copy(certificate = summary, problem = null) }

    /** Stores a failed certificate read; ignored when that card was removed or replaced meanwhile. */
    fun withProblem(card: WalletCard, problem: Throwable): WalletState =
        replace(card) { it.copy(certificate = null, problem = problem) }

    fun select(readerId: String): WalletState =
        if (cards.any { it.readerId == readerId }) copy(selectedReaderId = readerId) else this

    /** "Recitește cardul": forget what is known about every inserted card and read them all again. */
    fun forgetCertificates(): Update {
        val cleared = cards.map { it.copy(certificate = null, problem = null) }
        return Update(copy(cards = cleared), cleared)
    }

    /** docs/10 §0.1, decided by the selected card (the one a signature would use). */
    fun light(busy: Boolean): StatusLight {
        val card = selectedCard
        return when {
            busy -> StatusLight.Busy
            readers.isEmpty() -> StatusLight.Idle
            card?.problem != null -> StatusLight.Error
            card?.certificate != null -> StatusLight.Ready
            card == null && readers.all { it.state == ReaderSlot.State.Error } -> StatusLight.Error
            else -> StatusLight.Reader
        }
    }

    /** docs/10 §0.2b two-state tray (UX-11). */
    fun tray(): TrayStatus {
        val usable = cards.filter { it.problem == null }
        if (usable.isNotEmpty()) {
            return TrayStatus(connected = true, card = usable.firstOrNull { it.readerId == selectedCard?.readerId } ?: usable.first())
        }
        val problem = selectedCard?.problem
        return TrayStatus(
            connected = false,
            problem = problem,
            readerError = problem == null && readers.isNotEmpty() && readers.all { it.state == ReaderSlot.State.Error },
        )
    }

    private fun replace(card: WalletCard, change: (WalletCard) -> WalletCard): WalletState {
        val index = cards.indexOfFirst { it.readerId == card.readerId && it.generation == card.generation }
        if (index < 0) return this
        return copy(cards = cards.toMutableList().also { it[index] = change(it[index]) })
    }
}
