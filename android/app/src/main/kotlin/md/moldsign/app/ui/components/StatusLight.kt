package md.moldsign.app.ui.components

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.UsbOff
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import md.moldsign.app.application.AppStatus
import md.moldsign.app.presentation.statusChipText
import md.moldsign.app.presentation.statusLabel
import md.moldsign.app.ui.theme.LocalStatusColors
import md.moldsign.app.ui.theme.forLight
import md.moldsign.core.StatusLight

/**
 * The status light in the top app bar (docs/10 §0.1, UX-01): a colored dot plus text in an M3 assist chip.
 * Green = card ready, amber = reader only / reading, blue = busy (pulses), red = error, no dot = idle (dimmed
 * glyph). The chip text is short; its accessibility label is the full status line, announced on change.
 */
@Composable
fun StatusLightChip(status: AppStatus, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val full = statusLabel(context, status)
    AssistChip(
        onClick = onClick,
        label = { Text(statusChipText(context, status), maxLines = 1, overflow = TextOverflow.Ellipsis) },
        leadingIcon = { StatusDot(status.light) },
        colors = AssistChipDefaults.assistChipColors(containerColor = MaterialTheme.colorScheme.surfaceContainerHigh),
        border = null,
        modifier = modifier.semantics(mergeDescendants = true) {
            contentDescription = full
            liveRegion = LiveRegionMode.Polite
        },
    )
}

/** The dot alone (wallet header, lists). Idle shows the dimmed reader glyph instead of a dot. */
@Composable
fun StatusDot(light: StatusLight, size: Dp = 10.dp) {
    val color = LocalStatusColors.current.forLight(light)
    if (color == null) {
        Icon(
            Icons.Outlined.UsbOff,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(AssistChipDefaults.IconSize).alpha(0.6f),
        )
        return
    }
    val pulse = if (light == StatusLight.Busy) {
        // Compose scales this with the system animator duration scale ("Remove animations" stops it).
        val transition = rememberInfiniteTransition(label = "busy")
        val a by transition.animateFloat(1f, 0.35f, infiniteRepeatable(tween(800), RepeatMode.Reverse), label = "pulse")
        a
    } else {
        1f
    }
    Box(Modifier.size(size).alpha(pulse).background(color, CircleShape))
}
