package md.moldsign.app.ui.screens

import android.Manifest
import android.content.Intent
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.FileOpen
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.VerifiedUser
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.core.net.toUri
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import md.moldsign.app.MainViewModel
import md.moldsign.app.R
import md.moldsign.app.ui.components.ConnectionGuide
import md.moldsign.app.ui.components.FileRow
import md.moldsign.app.ui.components.StatusCard
import md.moldsign.app.ui.theme.LocalStatusColors
import md.moldsign.app.ui.theme.Tokens
import md.moldsign.core.ReaderState
import md.moldsign.core.SigningStep
import java.text.DateFormat

@Composable
private fun ScreenColumn(padding: PaddingValues, content: @Composable () -> Unit) {
    Column(
        Modifier
            .fillMaxSize()
            .padding(padding)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = Tokens.S4, vertical = Tokens.S3),
        verticalArrangement = Arrangement.spacedBy(Tokens.S4),
    ) { content() }
}

@Composable
private fun ReaderStatus(vm: MainViewModel, large: Boolean = false) {
    val state by vm.readerState.collectAsStateWithLifecycle()
    val cert by vm.certificate.collectAsStateWithLifecycle()
    val cardError by vm.cardError.collectAsStateWithLifecycle()
    StatusCard(state, cert, cardError, onAllowUsb = vm::requestUsbPermission, large = large)
    if (state == ReaderState.NoReader) ConnectionGuide()
}

/** Semnează: status, document picker (SAF OpenDocument), FormatChip; the FAB lives in the scaffold. */
@Composable
fun SignScreen(vm: MainViewModel, padding: PaddingValues) {
    val doc by vm.signDoc.collectAsStateWithLifecycle()
    val format by vm.signFormat.collectAsStateWithLifecycle()
    val progress by vm.progress.collectAsStateWithLifecycle()
    val working by vm.working.collectAsStateWithLifecycle()
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { vm.pickForSigning(it) }

    ScreenColumn(padding) {
        ReaderStatus(vm)
        val current = doc
        if (current == null) {
            OutlinedButton(
                onClick = { picker.launch(arrayOf("*/*")) },
                modifier = Modifier.fillMaxWidth().height(96.dp),
                shape = RoundedCornerShape(Tokens.RadiusCard),
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Outlined.FileOpen, contentDescription = null)
                        Spacer(Modifier.width(Tokens.S2))
                        Text(stringResource(R.string.action_choose_document), style = MaterialTheme.typography.titleMedium)
                    }
                    Text(stringResource(R.string.format_hint), style = MaterialTheme.typography.bodySmall)
                }
            }
            Text(stringResource(R.string.sign_empty_hint), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        } else {
            FileRow(current, format ?: current.defaultFormat, vm::setSignFormat, vm::clearSignDoc)
        }
        if (working) {
            StepLine(progress)
        }
    }
}

/** Vertical StepProgress collapsed to the active step (docs/10 §3). */
@Composable
private fun StepLine(step: SigningStep) {
    Column {
        LinearProgressIndicator(Modifier.fillMaxWidth())
        Spacer(Modifier.height(Tokens.S2))
        Text(step.name, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

/** Verifică: pick a signed PDF / XAdES and validate (validator is AND-01). */
@Composable
fun VerifyScreen(vm: MainViewModel, padding: PaddingValues) {
    val doc by vm.verifyDoc.collectAsStateWithLifecycle()
    val working by vm.working.collectAsStateWithLifecycle()
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { vm.pickForVerify(it) }

    ScreenColumn(padding) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Outlined.VerifiedUser, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(28.dp))
            Spacer(Modifier.width(Tokens.S3))
            Text(stringResource(R.string.verify_hint), style = MaterialTheme.typography.bodyLarge)
        }
        val current = doc
        if (current == null) {
            OutlinedButton(onClick = { picker.launch(arrayOf("application/pdf", "text/xml", "application/xml", "*/*")) }, modifier = Modifier.fillMaxWidth()) {
                Text(stringResource(R.string.action_choose_document))
            }
        } else {
            FileRow(current, format = null, onFormat = null, onRemove = vm::clearVerifyDoc)
            Button(onClick = vm::verify, enabled = !working, modifier = Modifier.fillMaxWidth()) {
                Text(stringResource(R.string.action_verify))
            }
        }
        if (working) LinearProgressIndicator(Modifier.fillMaxWidth())
    }
}

/** Browser: bridge toggle (foreground service) + open the portal in Chrome. */
@Composable
fun BrowserScreen(vm: MainViewModel, padding: PaddingValues) {
    val running by vm.bridgeRunning.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val status = LocalStatusColors.current
    val notifications = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { vm.setBridge(true) }

    ScreenColumn(padding) {
        Card(
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
            shape = RoundedCornerShape(Tokens.RadiusCard),
        ) {
            Column(Modifier.padding(Tokens.S4)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Outlined.Language, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                    Spacer(Modifier.width(Tokens.S3))
                    Column(Modifier.weight(1f)) {
                        Text(stringResource(R.string.bridge_toggle), style = MaterialTheme.typography.titleMedium)
                        Text(
                            stringResource(if (running) R.string.bridge_on else R.string.bridge_off),
                            color = if (running) status.success else MaterialTheme.colorScheme.onSurfaceVariant,
                            style = MaterialTheme.typography.bodyMedium,
                        )
                    }
                    Switch(
                        checked = running,
                        onCheckedChange = { on ->
                            if (on && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                notifications.launch(Manifest.permission.POST_NOTIFICATIONS)
                            } else {
                                vm.setBridge(on)
                            }
                        },
                    )
                }
                Spacer(Modifier.height(Tokens.S3))
                Text(stringResource(R.string.bridge_description), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        Button(
            onClick = { context.startActivity(Intent(Intent.ACTION_VIEW, "https://msign.gov.md".toUri())) },
            modifier = Modifier.fillMaxWidth(),
        ) { Text(stringResource(R.string.action_open_portal)) }
    }
}

/** Card: holder, issuer, validity, serial, reader; remember / delete PIN. */
@Composable
fun CardScreen(vm: MainViewModel, padding: PaddingValues) {
    val state by vm.readerState.collectAsStateWithLifecycle()
    val cert by vm.certificate.collectAsStateWithLifecycle()
    ScreenColumn(padding) {
        ReaderStatus(vm, large = true)
        val c = cert
        Card(
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
            shape = RoundedCornerShape(Tokens.RadiusCard),
        ) {
            if (c == null) {
                Text(stringResource(R.string.card_not_read), Modifier.padding(Tokens.S4), color = MaterialTheme.colorScheme.onSurfaceVariant)
            } else {
                val fmt = DateFormat.getDateInstance(DateFormat.MEDIUM)
                val itemColors = ListItemDefaults.colors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow)
                ListItem(headlineContent = { Text(c.commonName) }, overlineContent = { Text(stringResource(R.string.card_holder)) }, colors = itemColors)
                HorizontalDivider()
                ListItem(headlineContent = { Text(c.issuerCommonName ?: c.issuerDn) }, overlineContent = { Text(stringResource(R.string.card_issuer)) }, colors = itemColors)
                HorizontalDivider()
                ListItem(
                    headlineContent = { Text("${fmt.format(c.notBefore)} – ${fmt.format(c.notAfter)}") },
                    overlineContent = { Text(stringResource(R.string.card_validity)) },
                    colors = itemColors,
                )
                HorizontalDivider()
                ListItem(headlineContent = { Text(c.serialHex) }, overlineContent = { Text(stringResource(R.string.card_serial)) }, colors = itemColors)
                (state as? ReaderState.CardPresent)?.let { present ->
                    HorizontalDivider()
                    ListItem(headlineContent = { Text(present.reader) }, overlineContent = { Text(stringResource(R.string.card_reader)) }, colors = itemColors)
                }
            }
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(Tokens.S2)) {
            OutlinedButton(onClick = vm::readCertificate, enabled = state is ReaderState.CardPresent) {
                Text(stringResource(R.string.action_read_certificate))
            }
            TextButton(onClick = vm::deleteStoredPin, enabled = c != null) {
                Text(stringResource(R.string.pin_stored_delete))
            }
        }
    }
}
