package md.moldsign.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import md.moldsign.app.R
import md.moldsign.app.errorText
import md.moldsign.app.ui.theme.LocalStatusColors
import md.moldsign.app.ui.theme.Tokens
import md.moldsign.core.CertificateSummary
import md.moldsign.core.ReaderState
import java.text.SimpleDateFormat
import java.util.Locale

/**
 * StatusCard (docs/10 §3): card art + holder + one status line + validity.
 * States: noReader · permission · empty · reading · ready · busy · error.
 */
@Composable
fun StatusCard(
    state: ReaderState,
    certificate: CertificateSummary?,
    cardError: Throwable?,
    onAllowUsb: () -> Unit,
    modifier: Modifier = Modifier,
    large: Boolean = false,
) {
    val colors = LocalStatusColors.current
    val statusLine: String
    var title: String? = null
    var dot: Color? = null
    var showProgress = false
    var isError = false
    when (state) {
        ReaderState.NoReader -> statusLine = stringResource(R.string.status_no_reader)
        is ReaderState.PermissionRequired -> {
            title = state.reader
            statusLine = stringResource(R.string.status_permission)
        }
        is ReaderState.Empty -> {
            title = state.reader
            statusLine = stringResource(R.string.status_empty)
        }
        is ReaderState.CardPresent -> {
            val holder = state.holder ?: certificate?.commonName
            when {
                cardError != null -> {
                    title = holder ?: state.reader
                    statusLine = errorText(cardError)
                    isError = true
                }
                holder == null -> {
                    title = state.reader
                    statusLine = stringResource(R.string.status_reading)
                    showProgress = true
                }
                else -> {
                    title = holder
                    statusLine = stringResource(R.string.status_reader_line, stringResource(R.string.status_ready), state.reader)
                    dot = colors.success
                }
            }
        }
        ReaderState.Busy -> {
            title = certificate?.commonName
            statusLine = stringResource(R.string.status_busy)
            showProgress = true
        }
        is ReaderState.Error -> {
            statusLine = state.message
            isError = true
        }
    }

    Card(
        modifier = modifier
            .fillMaxWidth()
            .semantics { stateDescription = statusLine },
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
        shape = RoundedCornerShape(Tokens.RadiusCard),
    ) {
        Column(Modifier.padding(Tokens.S4)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                CardArt(outlined = state == ReaderState.NoReader || state is ReaderState.PermissionRequired, width = if (large) 88.dp else 56.dp)
                Spacer(Modifier.width(Tokens.S4))
                Column(Modifier.weight(1f)) {
                    if (title != null) {
                        Text(
                            title,
                            style = if (large) MaterialTheme.typography.titleLarge else MaterialTheme.typography.titleMedium,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        if (dot != null) {
                            Box(Modifier.size(8.dp).background(dot, CircleShape))
                            Spacer(Modifier.width(Tokens.S2))
                        }
                        if (isError) {
                            Icon(Icons.Outlined.ErrorOutline, contentDescription = null, tint = colors.danger, modifier = Modifier.size(16.dp))
                            Spacer(Modifier.width(Tokens.S1))
                        }
                        Text(
                            statusLine,
                            style = MaterialTheme.typography.bodyMedium,
                            color = if (isError) colors.danger else MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                    certificate?.takeIf { state is ReaderState.CardPresent && cardError == null }?.let {
                        Text(
                            stringResource(R.string.status_valid_until, SimpleDateFormat("MM.yyyy", Locale.ROOT).format(it.notAfter)),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
            }
            if (showProgress) {
                Spacer(Modifier.height(Tokens.S3))
                LinearProgressIndicator(Modifier.fillMaxWidth())
            }
            if (state is ReaderState.PermissionRequired) {
                Spacer(Modifier.height(Tokens.S3))
                Text(stringResource(R.string.usb_permission_body), style = MaterialTheme.typography.bodyMedium)
                Spacer(Modifier.height(Tokens.S3))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                    Button(onClick = onAllowUsb) { Text(stringResource(R.string.action_allow)) }
                }
            }
        }
    }
}

/** Blue card with the yellow chip; outlined when no reader is connected. */
@Composable
fun CardArt(outlined: Boolean, width: Dp = 56.dp) {
    val colors = LocalStatusColors.current
    val height = width * 0.63f
    val shape = RoundedCornerShape(width * 0.11f)
    val base = if (outlined) {
        Modifier.border(1.5.dp, MaterialTheme.colorScheme.outline, shape)
    } else {
        Modifier.background(colors.brand, shape)
    }
    Box(Modifier.size(width, height).then(base)) {
        Box(
            Modifier
                .padding(start = width * 0.12f, top = height * 0.3f)
                .size(width * 0.22f, height * 0.3f)
                .background(if (outlined) MaterialTheme.colorScheme.outlineVariant else colors.accent, RoundedCornerShape(3.dp)),
        )
    }
}

/** Compact reader status for the top app bar. */
@Composable
fun ReaderStatusChip(state: ReaderState) {
    val colors = LocalStatusColors.current
    val (label, color) = when (state) {
        ReaderState.NoReader -> stringResource(R.string.status_no_reader) to MaterialTheme.colorScheme.outline
        is ReaderState.PermissionRequired -> stringResource(R.string.status_permission) to colors.warning
        is ReaderState.Empty -> stringResource(R.string.status_empty) to colors.warning
        is ReaderState.CardPresent -> stringResource(R.string.status_ready) to colors.success
        ReaderState.Busy -> stringResource(R.string.status_busy) to colors.brand
        is ReaderState.Error -> stringResource(R.string.status_error) to colors.danger
    }
    Row(
        Modifier
            .padding(end = Tokens.S3)
            .background(MaterialTheme.colorScheme.surfaceContainerHigh, CircleShape)
            .padding(horizontal = Tokens.S3, vertical = Tokens.S1),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(8.dp).background(color, CircleShape))
        Spacer(Modifier.width(Tokens.S2))
        Text(label, style = MaterialTheme.typography.labelMedium, maxLines = 1)
    }
}
