package md.moldsign.app.presentation

import md.moldsign.app.R
import md.moldsign.app.application.AppStatus

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import md.moldsign.core.CardError
import md.moldsign.core.ReaderSlot
import md.moldsign.core.SigningStep
import md.moldsign.core.StatusLight
import md.moldsign.core.WalletState

/**
 * Calm, actionable copy for the error taxonomy (docs/09 §3.3, docs/10 principle 5).
 * Raw status words never reach the UI text; they stay in logs / technical details.
 */
fun errorText(context: Context, e: Throwable): String = when (e) {
    is CardError.NoReader -> context.getString(R.string.error_no_reader)
    is CardError.NoCard -> context.getString(R.string.error_no_card)
    is CardError.WrongPin -> context.getString(R.string.error_wrong_pin, e.remaining)
    is CardError.PinBlocked -> context.getString(R.string.error_pin_blocked)
    is CardError.CardChanged -> context.getString(R.string.error_card_changed)
    is CardError.CardStateStuck -> context.getString(R.string.error_card_stuck)
    is CardError.SmOutOfSync -> context.getString(R.string.error_sm_out_of_sync)
    is CardError.Network -> context.getString(R.string.error_network, e.service)
    is CardError.Cancelled -> ""
    is CardError.CardNotResponding, is CardError.UnexpectedStatus, is CardError.Protocol ->
        context.getString(R.string.error_card_stuck)
    is NotImplementedError -> context.getString(R.string.error_not_ported)
    else -> context.getString(R.string.error_generic, e.message ?: e.javaClass.simpleName)
}

@Composable
fun errorText(e: Throwable): String = errorText(LocalContext.current, e)

fun messageText(context: Context, m: UiMessage): String = when (m) {
    is UiMessage.Error -> errorText(context, m.error)
    is UiMessage.Text -> context.getString(m.res)
    is UiMessage.Saved -> context.getString(m.res)
    is UiMessage.Status -> statusLabel(context, m.status)
}

private fun WalletState.waitingForPermission() = cards.isEmpty() && readers.any { it.state == ReaderSlot.State.PermissionRequired }

/**
 * The status light's text (docs/10 §0.1): the accessibility label of the top-bar chip and the bridge
 * notification's content. Color is never the only signal, this text always goes with it.
 */
fun statusLabel(context: Context, status: AppStatus): String {
    val wallet = status.wallet
    return when (status.light) {
        StatusLight.Ready -> {
            val holder = wallet.selectedCard?.certificate?.commonName.orEmpty()
            val ready = wallet.readyCards.size
            if (ready > 1) {
                context.getString(R.string.light_ready_many, holder, context.resources.getQuantityString(R.plurals.cards_count, ready, ready))
            } else {
                context.getString(R.string.light_ready, holder)
            }
        }
        StatusLight.Reader -> context.getString(
            when {
                wallet.waitingForPermission() -> R.string.light_permission
                wallet.selectedCard?.isReading == true -> R.string.light_reading
                else -> R.string.light_reader
            },
        )
        StatusLight.Busy -> context.getString(R.string.light_busy)
        StatusLight.Error -> wallet.selectedCard?.problem?.let { errorText(context, it) }
            ?: context.getString(R.string.light_reader_error)
        StatusLight.Idle -> context.getString(R.string.light_idle)
    }
}

/**
 * Two-state tray text (docs/10 §0.2b, UX-11) for the bridge notification (and a future Quick Settings tile):
 * "Card conectat · {holder}" while any usable card is inserted, else "Niciun card conectat" or the error's one-liner.
 */
fun trayText(context: Context, wallet: WalletState): String {
    val tray = wallet.tray()
    return when {
        tray.connected -> context.getString(R.string.tray_connected, tray.card?.certificate?.commonName ?: tray.card?.readerName.orEmpty())
        tray.problem != null -> errorText(context, tray.problem!!)
        tray.readerError -> context.getString(R.string.light_reader_error)
        else -> context.getString(R.string.tray_no_card)
    }
}

/** Short chip text for the top app bar (the full [statusLabel] is its accessibility label). */
fun statusChipText(context: Context, status: AppStatus): String = context.getString(
    when (status.light) {
        StatusLight.Ready -> R.string.chip_ready
        StatusLight.Reader -> when {
            status.wallet.waitingForPermission() -> R.string.chip_permission
            status.wallet.selectedCard?.isReading == true -> R.string.chip_reading
            else -> R.string.chip_reader
        }
        StatusLight.Busy -> R.string.chip_busy
        StatusLight.Error -> R.string.chip_error
        StatusLight.Idle -> R.string.chip_idle
    },
)

fun stepText(context: Context, step: SigningStep): String = when (step) {
    SigningStep.Idle, SigningStep.Connecting -> context.getString(R.string.step_connecting)
    SigningStep.Authenticating -> context.getString(R.string.step_authenticating)
    SigningStep.ReadingCertificate -> context.getString(R.string.step_reading_certificate)
    SigningStep.VerifyingPin -> context.getString(R.string.step_verifying_pin)
    SigningStep.Signing -> context.getString(R.string.step_signing)
    SigningStep.Timestamping -> context.getString(R.string.step_timestamping)
    SigningStep.Revocation -> context.getString(R.string.step_revocation)
    SigningStep.Writing -> context.getString(R.string.step_writing)
    SigningStep.Done -> context.getString(R.string.step_done)
}
