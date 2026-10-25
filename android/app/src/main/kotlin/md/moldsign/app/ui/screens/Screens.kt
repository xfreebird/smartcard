package md.moldsign.app.ui.screens

import android.Manifest
import android.content.Intent
import android.net.Uri
import androidx.annotation.StringRes
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
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
import androidx.compose.material.icons.automirrored.outlined.OpenInNew
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.DeleteSweep
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.ExpandLess
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material.icons.outlined.VerifiedUser
import androidx.compose.material.icons.outlined.WarningAmber
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.core.net.toUri
import androidx.lifecycle.compose.LifecycleResumeEffect
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import md.moldsign.app.MainViewModel
import md.moldsign.app.VerifyOutcome
import md.moldsign.app.R
import md.moldsign.app.errorText
import md.moldsign.app.statusLabel
import md.moldsign.app.stepText
import md.moldsign.app.ui.components.CardWallet
import md.moldsign.app.ui.components.ConnectionGuide
import md.moldsign.app.ui.components.DocumentAddTile
import md.moldsign.app.ui.components.DocumentList
import md.moldsign.app.ui.components.DocumentPickZone
import md.moldsign.app.ui.components.DocumentRow
import md.moldsign.app.ui.theme.LocalStatusColors
import md.moldsign.app.ui.theme.Tokens
import md.moldsign.core.ActivityEntry
import md.moldsign.core.SigningStep
import md.moldsign.core.ValidationReport
import md.moldsign.core.Verdict
import md.moldsign.core.WalletCard
import java.text.DateFormat
import java.text.SimpleDateFormat
import java.util.Locale

/** Scrollable screen body; the wallet bleeds to the edges, everything else gets the 16 dp gutter. */
@Composable
private fun ScreenColumn(padding: PaddingValues, content: @Composable ColumnScope.() -> Unit) {
    Column(
        Modifier
            .fillMaxSize()
            .padding(padding)
            .verticalScroll(rememberScrollState())
            .padding(vertical = Tokens.S3),
        verticalArrangement = Arrangement.spacedBy(Tokens.S4),
        content = content,
    )
}

private val Gutter = Modifier.padding(horizontal = Tokens.S4)

@Composable
private fun SectionHeader(title: String, action: (@Composable () -> Unit)? = null) {
    Row(Gutter.fillMaxWidth().height(40.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(title, style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.weight(1f))
        action?.invoke()
    }
}

/** Semnează: card wallet on top, document list (SAF OpenMultipleDocuments) with FormatChips; the FAB is in the scaffold. */
@Composable
fun SignScreen(vm: MainViewModel, padding: PaddingValues, onOpenCard: () -> Unit) {
    val status by vm.status.collectAsStateWithLifecycle()
    val items by vm.signItems.collectAsStateWithLifecycle()
    val progress by vm.progress.collectAsStateWithLifecycle()
    val working by vm.working.collectAsStateWithLifecycle()
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.OpenMultipleDocuments()) { vm.addForSigning(it) }

    ScreenColumn(padding) {
        CardWallet(
            status.wallet,
            onSelect = vm::selectCard,
            onReread = vm::rereadCards,
            onAllowUsb = vm::requestUsbPermission,
            onOpen = onOpenCard,
        )
        if (working) StepCard(progress)
        Column {
            SectionHeader(stringResource(R.string.sign_documents))
            Column(Gutter, verticalArrangement = Arrangement.spacedBy(Tokens.S3)) {
                val pick = { picker.launch(arrayOf("*/*")) }
                if (items.isEmpty()) {
                    DocumentPickZone(onPick = pick)
                } else {
                    DocumentList(items, onFormat = vm::setFormat, onRemove = vm::remove)
                    // No accent FAB while signing is impossible (docs/10): say why instead.
                    val canSign = status.wallet.selectedCard?.isReady == true && !status.busy
                    if (!canSign && !working) SignBlockedHint(statusLabel(LocalContext.current, status))
                    DocumentAddTile(onPick = pick)
                }
            }
        }
        Spacer(Modifier.height(72.dp)) // room for the extended FAB
    }
}

@Composable
private fun SignBlockedHint(text: String) {
    Row(Modifier.fillMaxWidth().padding(horizontal = Tokens.S1), verticalAlignment = Alignment.CenterVertically) {
        Icon(Icons.Outlined.Info, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(18.dp))
        Spacer(Modifier.width(Tokens.S2))
        Text(text, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

/** StepProgress collapsed to the active step (docs/10 §3, phones). */
@Composable
private fun StepCard(step: SigningStep) {
    val context = LocalContext.current
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.secondaryContainer),
        shape = RoundedCornerShape(Tokens.RadiusCard),
        modifier = Gutter.fillMaxWidth(),
    ) {
        Row(Modifier.padding(Tokens.S4), verticalAlignment = Alignment.CenterVertically) {
            CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.5.dp)
            Spacer(Modifier.width(Tokens.S3))
            Text(stepText(context, step), style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSecondaryContainer)
        }
    }
}

/** Verifică: pick a signed PDF / XAdES and validate (the validator is AND-01). */
@Composable
fun VerifyScreen(vm: MainViewModel, padding: PaddingValues) {
    val doc by vm.verifyDoc.collectAsStateWithLifecycle()
    val outcome by vm.verifyOutcome.collectAsStateWithLifecycle()
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { vm.pickForVerify(it) }
    val attach = rememberLauncherForActivityResult(ActivityResultContracts.OpenMultipleDocuments()) { vm.addVerifyDocuments(it) }

    ScreenColumn(padding) {
        Column(Gutter, verticalArrangement = Arrangement.spacedBy(Tokens.S4)) {
            val current = doc
            if (current == null) {
                DocumentPickZone(
                    onPick = { picker.launch(arrayOf("application/pdf", "text/xml", "application/xml", "*/*")) },
                    title = stringResource(R.string.action_choose_document),
                    body = stringResource(R.string.verify_hint),
                )
            } else {
                Card(
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
                    shape = RoundedCornerShape(Tokens.RadiusCard),
                ) { DocumentRow(current, format = null, onFormat = null, onRemove = vm::clearVerifyDoc) }
                outcome?.let { result ->
                    VerdictBadge(result)
                    if (result.missingDocuments.isNotEmpty()) {
                        MissingDocuments(result.missingDocuments) { attach.launch(arrayOf("*/*")) }
                    }
                    result.reports.forEach { SignatureCard(it) }
                }
            }
        }
    }
}

/** docs/10 VerdictBadge: a large icon and the verdict in words (color is never the only signal). */
@Composable
private fun VerdictBadge(outcome: VerifyOutcome) {
    val colors = LocalStatusColors.current
    val (icon, tint, title, body) = when (outcome.verdict) {
        Verdict.Valid -> Verdict4(Icons.Outlined.CheckCircle, colors.success, R.string.verdict_valid, R.string.verdict_valid_body)
        Verdict.Invalid -> Verdict4(Icons.Outlined.ErrorOutline, colors.danger, R.string.verdict_invalid, R.string.verdict_invalid_body)
        Verdict.Unconfirmed -> Verdict4(
            Icons.Outlined.WarningAmber, colors.warning, R.string.verdict_unconfirmed,
            if (outcome.missingDocuments.isNotEmpty()) R.string.verdict_unconfirmed_documents else R.string.verdict_unconfirmed_chain,
        )
        Verdict.NoSignature -> Verdict4(Icons.Outlined.Info, MaterialTheme.colorScheme.onSurfaceVariant, R.string.verdict_none, R.string.verdict_none_body)
    }
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
        shape = RoundedCornerShape(Tokens.RadiusCard),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Row(Modifier.padding(Tokens.S4), horizontalArrangement = Arrangement.spacedBy(Tokens.S3), verticalAlignment = Alignment.CenterVertically) {
            Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(40.dp))
            Column {
                Text(stringResource(title), style = MaterialTheme.typography.titleLarge)
                Text(stringResource(body), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

private data class Verdict4(val icon: ImageVector, val tint: Color, @StringRes val title: Int, @StringRes val body: Int)

/** A detached XAdES signature names the file it signed: the user picks it (the document is matched by file name). */
@Composable
private fun MissingDocuments(names: List<String>, onPick: () -> Unit) {
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
        shape = RoundedCornerShape(Tokens.RadiusCard),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(Modifier.padding(Tokens.S4), verticalArrangement = Arrangement.spacedBy(Tokens.S3)) {
            Text(stringResource(R.string.verify_needs_document, names.joinToString()), style = MaterialTheme.typography.bodyMedium)
            FilledTonalButton(onClick = onPick) { Text(stringResource(R.string.verify_add_document)) }
        }
    }
}

/** docs/10 SignatureCard: signer, times and level, the three check chips and a technical-details disclosure. */
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun SignatureCard(report: ValidationReport) {
    var details by remember { mutableStateOf(false) }
    val dateTime = remember { DateFormat.getDateTimeInstance(DateFormat.MEDIUM, DateFormat.SHORT) }
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
        shape = RoundedCornerShape(Tokens.RadiusCard),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(Modifier.padding(Tokens.S4), verticalArrangement = Arrangement.spacedBy(Tokens.S2)) {
            Text(report.signerName ?: stringResource(R.string.sig_unknown_signer), style = MaterialTheme.typography.titleMedium)
            report.level?.let { Text(it, style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant) }
            report.signingTime?.let { Text(stringResource(R.string.sig_signed_at, dateTime.format(it)), style = MaterialTheme.typography.bodyMedium) }
            report.timestampTime?.let { Text(stringResource(R.string.sig_timestamp, dateTime.format(it)), style = MaterialTheme.typography.bodyMedium) }
            FlowRow(horizontalArrangement = Arrangement.spacedBy(Tokens.S2), verticalArrangement = Arrangement.spacedBy(Tokens.S2)) {
                CheckChip(R.string.sig_integrity, if (report.missingDocuments.isNotEmpty()) null else report.integrityOk)
                CheckChip(R.string.sig_signature, report.signatureOk)
                CheckChip(R.string.sig_chain, report.chainOk)
            }
            if (report.details.isNotEmpty()) {
                TextButton(onClick = { details = !details }, contentPadding = PaddingValues(horizontal = 0.dp)) {
                    Text(stringResource(R.string.sig_details))
                    Icon(if (details) Icons.Outlined.ExpandLess else Icons.Outlined.ExpandMore, contentDescription = null)
                }
                if (details) {
                    Text(report.details.joinToString("\n"), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}

/** [ok] `null` = could not be checked (unknown chain, missing document): a warning, not a failure. */
@Composable
private fun CheckChip(@StringRes label: Int, ok: Boolean?) {
    val colors = LocalStatusColors.current
    val (icon, tint) = when (ok) {
        true -> Icons.Outlined.CheckCircle to colors.success
        false -> Icons.Outlined.ErrorOutline to colors.danger
        null -> Icons.Outlined.WarningAmber to colors.warning
    }
    AssistChip(
        onClick = {},
        label = { Text(stringResource(label)) },
        leadingIcon = { Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(18.dp)) },
    )
}

/**
 * Activitate: signed / verified documents (only while the file is still reachable, re-checked whenever the screen is
 * shown) and browser requests (always kept), newest first; "Golește lista" asks first.
 */
@Composable
fun ActivityScreen(vm: MainViewModel, padding: PaddingValues) {
    val entries by vm.activity.collectAsStateWithLifecycle()
    var confirm by remember { mutableStateOf(false) }
    // "Salvează ca…": the system save dialog, one launcher per file type so the picker proposes the right extension.
    var saveSource by remember { mutableStateOf<Uri?>(null) }
    val savePdf = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/pdf")) { vm.saveCopy(saveSource, it) }
    val saveXml = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/xml")) { vm.saveCopy(saveSource, it) }
    val saveAs: (String) -> Unit = { name -> if (name.endsWith(".xml", ignoreCase = true)) saveXml.launch(name) else savePdf.launch(name) }
    LifecycleResumeEffect(Unit) {
        vm.pruneActivity()
        onPauseOrDispose { }
    }
    ScreenColumn(padding) {
        if (entries.isEmpty()) {
            Column(
                Gutter.fillMaxWidth().padding(top = Tokens.S8),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Icon(Icons.Outlined.History, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(48.dp))
                Spacer(Modifier.height(Tokens.S3))
                Text(stringResource(R.string.activity_empty_title), style = MaterialTheme.typography.titleMedium)
                Text(
                    stringResource(R.string.activity_empty_body),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                )
            }
        } else {
            Column {
                SectionHeader(stringResource(R.string.activity_recent)) {
                    TextButton(onClick = { confirm = true }) {
                        Icon(Icons.Outlined.DeleteSweep, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(Tokens.S2))
                        Text(stringResource(R.string.activity_clear))
                    }
                }
                Card(
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
                    shape = RoundedCornerShape(Tokens.RadiusCard),
                    modifier = Gutter.fillMaxWidth(),
                ) {
                    entries.forEachIndexed { i, e ->
                        if (i > 0) HorizontalDivider(Modifier.padding(start = 56.dp))
                        ActivityRow(e, onSaveAs = { source, name -> saveSource = source; saveAs(name) })
                    }
                }
            }
        }
    }
    if (confirm) {
        AlertDialog(
            onDismissRequest = { confirm = false },
            icon = { Icon(Icons.Outlined.DeleteSweep, contentDescription = null) },
            title = { Text(stringResource(R.string.activity_clear_title)) },
            text = { Text(stringResource(R.string.activity_clear_body)) },
            confirmButton = {
                TextButton(onClick = {
                    confirm = false
                    vm.clearActivity()
                }) { Text(stringResource(R.string.activity_clear_confirm)) }
            },
            dismissButton = { TextButton(onClick = { confirm = false }) { Text(stringResource(R.string.action_cancel)) } },
        )
    }
}

private fun mimeOf(name: String) = if (name.endsWith(".xml", ignoreCase = true)) "application/xml" else "application/pdf"

@Composable
private fun ActivityRow(e: ActivityEntry, onSaveAs: (source: Uri, name: String) -> Unit) {
    val context = LocalContext.current
    val colors = LocalStatusColors.current
    val uri = e.documentUri?.toUri()?.takeIf { it.scheme == "content" }
    var menu by remember { mutableStateOf(false) }
    // content:// entries open in the default viewer (the persisted permission travels with the intent).
    val open: (() -> Unit)? = uri?.let { u ->
        {
            runCatching {
                context.startActivity(Intent(Intent.ACTION_VIEW, u).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK))
            }
        }
    }
    val share: (() -> Unit)? = uri?.let { u ->
        {
            val send = Intent(Intent.ACTION_SEND)
                .setType(mimeOf(e.title))
                .putExtra(Intent.EXTRA_STREAM, u)
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            runCatching { context.startActivity(Intent.createChooser(send, null).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
        }
    }
    ListItem(
        leadingContent = {
            when {
                e.kind == ActivityEntry.Kind.Browser -> Icon(Icons.Outlined.Language, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                e.ok -> Icon(Icons.Outlined.CheckCircle, contentDescription = null, tint = colors.success)
                else -> Icon(Icons.Outlined.ErrorOutline, contentDescription = null, tint = colors.danger)
            }
        },
        headlineContent = { Text(e.title, maxLines = 1, overflow = TextOverflow.MiddleEllipsis) },
        supportingContent = { Text(e.subtitle, maxLines = 2, overflow = TextOverflow.Ellipsis) },
        trailingContent = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(activityTime(e.timeMillis), style = MaterialTheme.typography.labelSmall)
                if (uri != null && open != null && share != null) {
                    Box {
                        IconButton(onClick = { menu = true }) {
                            Icon(Icons.Outlined.MoreVert, contentDescription = stringResource(R.string.action_more))
                        }
                        DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                            DropdownMenuItem(text = { Text(stringResource(R.string.action_open)) }, onClick = { menu = false; open() })
                            DropdownMenuItem(text = { Text(stringResource(R.string.action_share)) }, onClick = { menu = false; share() })
                            DropdownMenuItem(text = { Text(stringResource(R.string.action_save_as)) }, onClick = { menu = false; onSaveAs(uri, e.title) })
                        }
                    }
                }
            }
        },
        colors = ListItemDefaults.colors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
        modifier = if (open != null) Modifier.clickable(onClick = open) else Modifier,
    )
}

/** Today → 14:05, otherwise 25.10.2026. */
private fun activityTime(millis: Long): String {
    val day = SimpleDateFormat("yyyyMMdd", Locale.ROOT)
    val now = System.currentTimeMillis()
    val pattern = if (day.format(millis) == day.format(now)) "HH:mm" else "dd.MM.yyyy"
    return SimpleDateFormat(pattern, Locale.ROOT).format(millis)
}

/**
 * Browser: the card the browser will sign with (same wallet component as Semnează / Card), the bridge toggle
 * (foreground service, its notification carries the two-state tray light) and the portal link.
 */
@Composable
fun BrowserScreen(vm: MainViewModel, padding: PaddingValues, onOpenCard: () -> Unit) {
    val running by vm.bridgeRunning.collectAsStateWithLifecycle()
    val wallet by vm.status.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val status = LocalStatusColors.current
    val notifications = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { vm.setBridge(true) }

    ScreenColumn(padding) {
        CardWallet(
            wallet.wallet,
            onSelect = vm::selectCard,
            onReread = vm::rereadCards,
            onAllowUsb = vm::requestUsbPermission,
            onOpen = onOpenCard,
        )
        Column(Gutter, verticalArrangement = Arrangement.spacedBy(Tokens.S4)) {
            Card(
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
                shape = RoundedCornerShape(Tokens.RadiusCard),
            ) {
                val itemColors = ListItemDefaults.colors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow)
                ListItem(
                    leadingContent = { Icon(Icons.Outlined.Language, contentDescription = null, tint = MaterialTheme.colorScheme.primary) },
                    headlineContent = { Text(stringResource(R.string.bridge_toggle)) },
                    supportingContent = {
                        Text(
                            stringResource(if (running) R.string.bridge_on else R.string.bridge_off),
                            color = if (running) status.success else MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    },
                    trailingContent = {
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
                    },
                    colors = itemColors,
                )
                Text(
                    stringResource(R.string.bridge_description),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(start = Tokens.S4, end = Tokens.S4, bottom = Tokens.S4),
                )
            }
            FilledTonalButton(
                onClick = { context.startActivity(Intent(Intent.ACTION_VIEW, "https://msign.gov.md".toUri())) },
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(stringResource(R.string.action_open_portal))
                Spacer(Modifier.width(Tokens.S2))
                Icon(Icons.AutoMirrored.Outlined.OpenInNew, contentDescription = null, modifier = Modifier.size(18.dp))
            }
        }
    }
}

/** Card: the large wallet, then the selected card's details as list items, "Recitește cardul", stored PIN. */
@Composable
fun CardScreen(vm: MainViewModel, padding: PaddingValues) {
    val status by vm.status.collectAsStateWithLifecycle()
    val wallet = status.wallet
    ScreenColumn(padding) {
        CardWallet(wallet, onSelect = vm::selectCard, onReread = vm::rereadCards, onAllowUsb = vm::requestUsbPermission, large = true)
        Column(Gutter, verticalArrangement = Arrangement.spacedBy(Tokens.S3)) {
            val card = wallet.selectedCard
            if (card != null) CardDetails(card)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(Tokens.S2), verticalAlignment = Alignment.CenterVertically) {
                FilledTonalButton(onClick = vm::rereadCards, enabled = wallet.cards.isNotEmpty() && !status.busy) {
                    Icon(Icons.Rounded.Refresh, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(Tokens.S2))
                    Text(stringResource(R.string.action_reread))
                }
                TextButton(onClick = vm::deleteStoredPin, enabled = card?.certificate != null) {
                    Text(stringResource(R.string.pin_stored_delete))
                }
            }
            if (wallet.readers.isEmpty()) {
                Spacer(Modifier.height(Tokens.S2))
                ConnectionGuide()
            }
            AboutRow()
        }
    }
}

/** "Despre eSemnBun" (UX-12): the public name and version; the codename stays in code. */
@Composable
private fun AboutRow() {
    val context = LocalContext.current
    var open by remember { mutableStateOf(false) }
    val version = remember {
        runCatching { context.packageManager.getPackageInfo(context.packageName, 0).versionName }.getOrNull().orEmpty()
    }
    ListItem(
        leadingContent = { Icon(Icons.Outlined.Info, contentDescription = null) },
        headlineContent = { Text(stringResource(R.string.about_title)) },
        supportingContent = { Text(stringResource(R.string.about_version, version)) },
        colors = ListItemDefaults.colors(containerColor = MaterialTheme.colorScheme.surface),
        modifier = Modifier.clickable { open = true },
    )
    if (open) {
        AlertDialog(
            onDismissRequest = { open = false },
            icon = { Icon(Icons.Outlined.Info, contentDescription = null) },
            title = { Text(stringResource(R.string.app_name)) },
            text = { Text(stringResource(R.string.about_version, version) + "\n\n" + stringResource(R.string.about_body)) },
            confirmButton = { TextButton(onClick = { open = false }) { Text(stringResource(R.string.action_close)) } },
        )
    }
}

@Composable
private fun CardDetails(card: WalletCard) {
    val itemColors = ListItemDefaults.colors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow)
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
        shape = RoundedCornerShape(Tokens.RadiusCard),
    ) {
        @Composable
        fun row(label: Int, value: String, divider: Boolean = true) {
            if (divider) HorizontalDivider(Modifier.padding(horizontal = Tokens.S4))
            ListItem(
                overlineContent = { Text(stringResource(label)) },
                headlineContent = { Text(value, maxLines = 2, overflow = TextOverflow.MiddleEllipsis) },
                colors = itemColors,
            )
        }
        val cert = card.certificate
        val problem = card.problem
        when {
            problem != null -> ListItem(
                leadingContent = { Icon(Icons.Outlined.ErrorOutline, contentDescription = null, tint = LocalStatusColors.current.danger) },
                headlineContent = { Text(stringResource(R.string.wallet_error_title)) },
                supportingContent = { Text(errorText(problem)) },
                colors = itemColors,
            )
            cert == null -> ListItem(
                leadingContent = { CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.5.dp) },
                headlineContent = { Text(stringResource(R.string.status_reading)) },
                colors = itemColors,
            )
            else -> {
                val fmt = DateFormat.getDateInstance(DateFormat.MEDIUM)
                row(R.string.card_holder, cert.commonName, divider = false)
                row(R.string.card_issuer, cert.issuerCommonName ?: cert.issuerDn)
                row(R.string.card_validity, "${fmt.format(cert.notBefore)} – ${fmt.format(cert.notAfter)}")
                row(R.string.card_serial, cert.serialHex)
                row(R.string.card_fingerprint, cert.sha1Hex.chunked(4).joinToString(" "))
            }
        }
        if (cert != null || problem != null) HorizontalDivider(Modifier.padding(horizontal = Tokens.S4))
        ListItem(
            overlineContent = { Text(stringResource(R.string.card_reader)) },
            headlineContent = { Text(card.readerName) },
            colors = itemColors,
        )
    }
}
