package md.moldsign.app.ui.components

import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.relocation.BringIntoViewRequester
import androidx.compose.foundation.relocation.bringIntoViewRequester
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.WarningAmber
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import md.moldsign.app.R
import md.moldsign.app.ui.theme.LocalStatusColors
import md.moldsign.core.ConsentRequest

private const val PIN_MIN = 4
private const val PIN_MAX = 8

/** Keyboard-aware consent dialog: scrollable details/field, with actions outside the scroll viewport. */
@Composable
fun PinSheet(
    request: ConsentRequest,
    rememberAvailable: Boolean,
    onConfirm: (pin: CharArray, remember: Boolean) -> Unit,
    onDismiss: () -> Unit,
) {
    var pin by remember(request) { mutableStateOf("") }
    var rememberPin by remember(request) { mutableStateOf(false) }
    val focus = remember { FocusRequester() }
    val field = remember { BringIntoViewRequester() }
    val valid = pin.length in PIN_MIN..PIN_MAX
    val status = LocalStatusColors.current

    fun confirm() {
        if (!valid) return
        val chars = pin.toCharArray()
        pin = ""
        onConfirm(chars, rememberPin)
    }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false),
    ) {
        val imeBottom = WindowInsets.ime.getBottom(LocalDensity.current)
        BoxWithConstraints(
            Modifier.fillMaxSize()
                .windowInsetsPadding(WindowInsets.safeDrawing.union(WindowInsets.ime))
                .semantics { testTagsAsResourceId = true },
            contentAlignment = Alignment.Center,
        ) {
            val shortViewport = maxHeight < 320.dp
            Surface(
                Modifier.padding(if (shortViewport) 8.dp else 16.dp)
                    .widthIn(max = 560.dp).fillMaxWidth().testTag("pin.dialog"),
                shape = RoundedCornerShape(24.dp),
                color = MaterialTheme.colorScheme.surfaceContainerHigh,
                tonalElevation = 6.dp,
            ) {
                Column(Modifier.padding(if (shortViewport) 8.dp else 20.dp)) {
                    Text(stringResource(R.string.pin_title),
                        modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center,
                        style = MaterialTheme.typography.titleLarge)
                    Column(
                        Modifier.weight(1f, fill = false).fillMaxWidth()
                            .verticalScroll(rememberScrollState()).testTag("pin.details"),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Icon(Icons.Outlined.Lock, contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(24.dp))
                        Text(stringResource(R.string.pin_for, request.certificate.commonName),
                            textAlign = TextAlign.Center, style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Text(
                            stringResource(R.string.consent_title, request.requester ?: stringResource(R.string.consent_you)) +
                                "\n" + request.documentNames.joinToString() + " · " + signatureLabels(request.format),
                            style = MaterialTheme.typography.bodySmall, textAlign = TextAlign.Center,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                        Spacer(Modifier.height(4.dp))
                        val description = stringResource(R.string.pin_field_description, pin.length)
                        BasicTextField(
                            value = pin,
                            onValueChange = { value -> pin = value.filter(Char::isDigit).take(PIN_MAX) },
                            visualTransformation = PasswordVisualTransformation(),
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword, imeAction = ImeAction.Done),
                            keyboardActions = KeyboardActions(onDone = { confirm() }),
                            modifier = Modifier.focusRequester(focus).bringIntoViewRequester(field)
                                .testTag("pin.field").semantics { contentDescription = description },
                            decorationBox = { PinBoxes(pin.length) },
                        )
                        Text(stringResource(R.string.pin_hint), style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                        request.attemptsLeft?.let { left ->
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                val color = if (left <= 2) status.warning else MaterialTheme.colorScheme.onSurfaceVariant
                                Icon(Icons.Outlined.WarningAmber, null, tint = color, modifier = Modifier.size(18.dp))
                                Spacer(Modifier.width(4.dp))
                                Text(stringResource(R.string.pin_attempts, left), color = color,
                                    style = MaterialTheme.typography.bodyMedium)
                            }
                        }
                        if (rememberAvailable) {
                            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                Text(stringResource(R.string.pin_remember), Modifier.weight(1f),
                                    style = MaterialTheme.typography.bodyLarge)
                                Switch(checked = rememberPin, onCheckedChange = { rememberPin = it })
                            }
                        }
                    }
                    Row(
                        Modifier.fillMaxWidth().padding(top = 8.dp).testTag("pin.actions"),
                        horizontalArrangement = Arrangement.End,
                    ) {
                        TextButton(onClick = onDismiss, modifier = Modifier.testTag("pin.cancel")) {
                            Text(stringResource(R.string.action_cancel))
                        }
                        Spacer(Modifier.width(8.dp))
                        Button(onClick = ::confirm, enabled = valid, modifier = Modifier.testTag("pin.confirm")) {
                            Text(stringResource(R.string.action_sign))
                        }
                    }
                }
            }
        }
        LaunchedEffect(Unit) {
            withFrameNanos { }
            focus.requestFocus()
        }
        // A short landscape viewport can scroll the explanation without losing the focused field/actions.
        LaunchedEffect(imeBottom) {
            if (imeBottom > 0) field.bringIntoView()
        }
    }
}

@Composable
private fun PinBoxes(filled: Int) {
    BoxWithConstraints(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
    val cellWidth = ((maxWidth - 28.dp) / PIN_MAX).coerceAtMost(44.dp)
    Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        repeat(PIN_MAX) { i ->
            val active = i == filled
            Box(
                Modifier
                    .size(width = cellWidth, height = 56.dp)
                    .border(
                        width = if (active) 2.dp else 1.dp,
                        color = if (active) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant,
                        shape = RoundedCornerShape(8.dp),
                    ),
                contentAlignment = Alignment.Center,
            ) {
                if (i < filled) Text("•", style = MaterialTheme.typography.titleLarge, color = Color.Unspecified)
            }
        }
    }
}
}
