package md.moldsign.app.ui.components

import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.WarningAmber
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import md.moldsign.app.R
import md.moldsign.app.ui.theme.LocalStatusColors
import md.moldsign.app.ui.theme.Tokens
import md.moldsign.core.ConsentRequest

private const val PIN_MIN = 4
private const val PIN_MAX = 8

/**
 * PIN sheet (docs/10 §4.3 / PinField): 4–8 boxed secure digits, numeric keyboard, remaining-attempts
 * line (warning at ≤ 2), "Ține minte PIN-ul" switch. Doubles as the consent sheet for bridge
 * requests by showing the requester and documents.
 *
 * The digits live in Compose state only while the sheet is open; [onConfirm] receives a CharArray the
 * signing service wipes after VERIFY. TODO(AND-06): block paste on the hidden field.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PinSheet(
    request: ConsentRequest,
    rememberAvailable: Boolean,
    onConfirm: (pin: CharArray, remember: Boolean) -> Unit,
    onDismiss: () -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var pin by remember { mutableStateOf("") }
    var rememberPin by remember { mutableStateOf(false) }
    val focus = remember { FocusRequester() }
    val valid = pin.length in PIN_MIN..PIN_MAX
    val status = LocalStatusColors.current

    fun confirm() {
        if (!valid) return
        val chars = pin.toCharArray()
        pin = ""
        onConfirm(chars, rememberPin)
    }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState, shape = RoundedCornerShape(topStart = Tokens.RadiusSheet, topEnd = Tokens.RadiusSheet)) {
        Column(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = Tokens.S6)
                .navigationBarsPadding()
                .padding(bottom = Tokens.S4),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Icon(Icons.Outlined.Lock, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(32.dp))
            Spacer(Modifier.height(Tokens.S2))
            Text(stringResource(R.string.pin_title), style = MaterialTheme.typography.titleLarge)
            Text(
                stringResource(R.string.pin_for, request.certificate.commonName),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.height(Tokens.S3))
            Text(
                stringResource(R.string.consent_title, request.requester ?: stringResource(R.string.consent_you)) +
                    "\n" + request.documentNames.joinToString() + " · " + request.format,
                style = MaterialTheme.typography.bodySmall,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.height(Tokens.S5))

            // Hidden text field drives the boxes; digits only, at most 8.
            val description = stringResource(R.string.pin_field_description, pin.length)
            BasicTextField(
                value = pin,
                onValueChange = { v -> pin = v.filter(Char::isDigit).take(PIN_MAX) },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword, imeAction = ImeAction.Done),
                keyboardActions = KeyboardActions(onDone = { confirm() }),
                modifier = Modifier
                    .focusRequester(focus)
                    .semantics { contentDescription = description },
                decorationBox = { PinBoxes(pin.length) },
            )
            Text(stringResource(R.string.pin_hint), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)

            request.attemptsLeft?.let { left ->
                Spacer(Modifier.height(Tokens.S3))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    val c = if (left <= 2) status.warning else MaterialTheme.colorScheme.onSurfaceVariant
                    Icon(Icons.Outlined.WarningAmber, contentDescription = null, tint = c, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(Tokens.S1))
                    Text(stringResource(R.string.pin_attempts, left), color = c, style = MaterialTheme.typography.bodyMedium)
                }
            }

            Spacer(Modifier.height(Tokens.S4))
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text(stringResource(R.string.pin_remember), modifier = Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge)
                Switch(checked = rememberPin, onCheckedChange = { rememberPin = it }, enabled = rememberAvailable)
            }
            Spacer(Modifier.height(Tokens.S4))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                TextButton(onClick = onDismiss) { Text(stringResource(R.string.action_cancel)) }
                Spacer(Modifier.width(Tokens.S2))
                Button(onClick = ::confirm, enabled = valid) { Text(stringResource(R.string.action_sign)) }
            }
        }
    }
    LaunchedEffect(Unit) { focus.requestFocus() }
}

@Composable
private fun PinBoxes(filled: Int) {
    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        repeat(PIN_MAX) { i ->
            val active = i == filled
            Box(
                Modifier
                    .size(width = 32.dp, height = 44.dp)
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
