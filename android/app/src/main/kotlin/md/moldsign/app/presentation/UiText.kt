package md.moldsign.app.presentation

import md.moldsign.app.R
import md.moldsign.app.application.AppStatus

import android.content.Context
import androidx.core.content.ContextCompat
import androidx.annotation.StringRes
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import md.moldsign.core.CardError
import md.moldsign.core.ReaderSlot
import md.moldsign.core.SigningStep
import md.moldsign.core.StatusLight
import md.moldsign.core.WalletState

/** Resolve background/service copy with the app language on Android 12 and earlier too. */
fun Context.appString(@StringRes res: Int, vararg args: Any): String =
    ContextCompat.getContextForLanguage(this).getString(res, *args)

/**
 * Calm, actionable copy for the error taxonomy (docs/09 §3.3, docs/10 principle 5).
 * Raw status words never reach the UI text; they stay in logs / technical details.
 */
fun errorText(context: Context, e: Throwable): String = when (e) {
    is md.moldsign.app.nfc.NfcUnavailable -> context.appString(R.string.nfc_enable)
    is md.moldsign.app.nfc.NfcConnectionLost -> context.appString(R.string.nfc_lost)
    is md.moldsign.app.nfc.NfcScanTimeout -> context.appString(R.string.nfc_timeout)
    is md.moldsign.app.nfc.NfcUnsupportedCard -> context.appString(R.string.nfc_unsupported)
    is CardError.NoReader -> context.appString(R.string.error_no_reader)
    is CardError.NoCard -> context.appString(R.string.error_no_card)
    is CardError.WrongPin -> context.appString(R.string.error_wrong_pin, e.remaining)
    is CardError.PinBlocked -> context.appString(R.string.error_pin_blocked)
    is CardError.CardChanged -> context.appString(R.string.error_card_changed)
    is CardError.CardStateStuck -> context.appString(R.string.error_card_stuck)
    is CardError.SmOutOfSync -> context.appString(R.string.error_sm_out_of_sync)
    is CardError.Network -> context.appString(R.string.operation_failed_safe)
    is CardError.Format -> "This document could not be signed. It may be damaged or use an unsupported format."
    is CardError.Cancelled -> ""
    is CardError.CardNotResponding, is CardError.UnexpectedStatus, is CardError.Protocol ->
        context.appString(R.string.error_card_stuck)
    is NotImplementedError -> context.appString(R.string.error_not_ported)
    is md.moldsign.core.UnsupportedTokenException -> context.appString(R.string.token_recognized_unsupported, e.family.displayName)
    else -> context.appString(R.string.operation_failed_safe)
}

@Composable
fun errorText(e: Throwable): String = errorText(LocalContext.current, e)

fun messageText(context: Context, m: UiMessage): String = when (m) {
    is UiMessage.Error -> errorText(context, m.error)
    is UiMessage.Text -> context.appString(m.res)
    is UiMessage.Saved -> context.appString(m.res)
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
                context.appString(R.string.light_ready_many, holder, ContextCompat.getContextForLanguage(context).resources.getQuantityString(R.plurals.cards_count, ready, ready))
            } else {
                context.appString(R.string.light_ready, holder)
            }
        }
        StatusLight.Reader -> context.appString(
            when {
                wallet.waitingForPermission() -> R.string.light_permission
                wallet.selectedCard?.isReading == true -> R.string.light_reading
                else -> R.string.light_reader
            },
        )
        StatusLight.Busy -> context.appString(R.string.light_busy)
        StatusLight.Error -> wallet.selectedCard?.problem?.let { errorText(context, it) }
            ?: context.appString(R.string.light_reader_error)
        StatusLight.Idle -> context.appString(R.string.light_idle)
    }
}

/**
 * Two-state tray text (docs/10 §0.2b, UX-11) for the bridge notification (and a future Quick Settings tile):
 * "Card conectat · {holder}" while any usable card is inserted, else "Niciun card conectat" or the error's one-liner.
 */
fun trayText(context: Context, wallet: WalletState): String {
    val tray = wallet.tray()
    return when {
        tray.connected -> context.appString(R.string.tray_connected, tray.card?.certificate?.commonName ?: tray.card?.readerName.orEmpty())
        tray.problem != null -> errorText(context, tray.problem!!)
        tray.readerError -> context.appString(R.string.light_reader_error)
        else -> context.appString(R.string.tray_no_card)
    }
}

/** Short chip text for the top app bar (the full [statusLabel] is its accessibility label). */
fun statusChipText(context: Context, status: AppStatus): String = context.appString(
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
    SigningStep.Idle, SigningStep.Connecting -> context.appString(R.string.step_connecting)
    SigningStep.Authenticating -> context.appString(R.string.step_authenticating)
    SigningStep.ReadingCertificate -> context.appString(R.string.step_reading_certificate)
    SigningStep.VerifyingPin -> context.appString(R.string.step_verifying_pin)
    SigningStep.Signing -> context.appString(R.string.step_signing)
    SigningStep.Timestamping -> context.appString(R.string.step_timestamping)
    SigningStep.Revocation -> context.appString(R.string.step_revocation)
    SigningStep.Writing -> context.appString(R.string.step_writing)
    SigningStep.Done -> context.appString(R.string.step_done)
}
