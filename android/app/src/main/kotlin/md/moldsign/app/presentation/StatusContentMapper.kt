package md.moldsign.app.presentation

import android.content.Context
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import md.moldsign.app.application.AppStatus
import md.moldsign.app.ui.components.StatusContent
import md.moldsign.app.ui.theme.StatusTone
import md.moldsign.app.ui.theme.Tokens
import md.moldsign.core.StatusLight
import md.moldsign.core.TrayStatus

fun AppStatus.toStatusContent(context: Context) =
    StatusContent(statusChipText(context, this), statusLabel(context, this), light.toTone())

internal fun StatusLight.toTone(): StatusTone = when (this) {
    StatusLight.Ready -> StatusTone.Success
    StatusLight.Reader -> StatusTone.Warning
    StatusLight.Busy -> StatusTone.Busy
    StatusLight.Error -> StatusTone.Danger
    StatusLight.Idle -> StatusTone.Idle
}

/** Foreground notification follows the bridge's two-state indicator. */
fun TrayStatus.notificationArgb(): Int = (if (connected) Tokens.SuccessLight else Color(0xFF757680)).toArgb()
