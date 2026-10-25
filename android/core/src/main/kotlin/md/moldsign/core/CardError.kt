package md.moldsign.core

/**
 * Error taxonomy of docs/09 §3.3. UI copy keys in brackets; the UI shows calm copy and puts the SW
 * into technical details only.
 *
 * PIN retry counter safety (R-07): callers must never retry [WrongPin] automatically and must
 * stop on [CardStateStuck] instead of re-running authentication.
 */
sealed class CardError(message: String, cause: Throwable? = null) : Exception(message, cause) {
    /** No USB/PCSC reader (`error.noReader`). */
    class NoReader(detail: String = "No card reader found") : CardError(detail)

    /** Reader present but no card / power-on failed (`error.noCard`). */
    class NoCard(detail: String = "No card in reader") : CardError(detail)

    /** Transport-level failure (timeout, short response, USB error). */
    class CardNotResponding(detail: String = "Card not responding", cause: Throwable? = null) : CardError(detail, cause)

    /** `63Cx` on VERIFY: delete the stored PIN, show [remaining], never auto-retry. */
    class WrongPin(val remaining: Int) : CardError("Wrong PIN, $remaining attempts remaining")

    /** `6983`: PIN blocked; unblock at CEV with the PUK (`error.pinBlocked`). */
    class PinBlocked : CardError("PIN blocked (SW=6983)")

    /** `6985`: card stuck in a state; ask to physically re-insert it (`error.cardStuck`). Do not retry auth. */
    class CardStateStuck : CardError("Conditions of use not satisfied (SW=6985): remove and re-insert the card")

    /** `6988` or a response MAC failure: drop the session and reconnect once. */
    class SmOutOfSync(detail: String) : CardError("Secure messaging out of sync: $detail")

    /** TSA / OCSP / CRL failure (`network(service)`). */
    class Network(val service: String, cause: Throwable? = null) : CardError("Network error contacting $service", cause)

    /** PDF / XML parse error (`format(message)`). */
    class Format(detail: String, cause: Throwable? = null) : CardError(detail, cause)

    /** User dismissed the PIN / consent UI. Silent in the UI. */
    class Cancelled : CardError("Cancelled by user")

    /** Any other non-9000 status word. */
    class UnexpectedStatus(val sw: Int, val context: String) :
        CardError("APDU error %04X%s".format(sw, if (context.isEmpty()) "" else " ($context)"))

    /** The card answered something structurally wrong (bad lengths, missing certificate, …). */
    class Protocol(detail: String) : CardError(detail)

    companion object {
        /**
         * Maps a non-9000 SW to the taxonomy. `63Cx` is NOT mapped here: only VERIFY may turn it
         * into [WrongPin] (an EXTERNAL AUTHENTICATE 63Cx must never delete a stored PIN).
         */
        fun fromStatusWord(sw: Int, context: String = ""): CardError = when (sw) {
            0x6983 -> PinBlocked()
            0x6985 -> CardStateStuck()
            0x6988 -> SmOutOfSync("SW=6988${if (context.isEmpty()) "" else " ($context)"}")
            else -> UnexpectedStatus(sw, context)
        }
    }
}
