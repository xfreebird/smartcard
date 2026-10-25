package md.moldsign.app

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import md.moldsign.core.CardError

/**
 * Calm, actionable copy for the error taxonomy (docs/09 §3.3, docs/10 principle 5).
 * Raw status words never reach the UI text; they stay in logs / technical details.
 */
fun errorText(context: Context, e: Throwable): String = when (e) {
    is CardError.NoReader -> context.getString(R.string.error_no_reader)
    is CardError.NoCard -> context.getString(R.string.error_no_card)
    is CardError.WrongPin -> context.getString(R.string.error_wrong_pin, e.remaining)
    is CardError.PinBlocked -> context.getString(R.string.error_pin_blocked)
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
}
