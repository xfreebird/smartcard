package md.moldsign.app.ui.screens

import md.moldsign.app.hostActivity
import md.moldsign.app.ui.components.signatureLabels
import androidx.compose.material.icons.outlined.FolderOpen
import androidx.compose.material3.FilterChip
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.DeleteSweep
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import kotlinx.coroutines.CancellationException
import androidx.core.net.toUri
import androidx.lifecycle.compose.LifecycleResumeEffect
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import md.moldsign.app.presentation.MainViewModel
import md.moldsign.app.application.VerifyOutcome
import md.moldsign.app.R
import md.moldsign.app.ui.theme.LocalStatusColors
import md.moldsign.app.ui.theme.Tokens
import md.moldsign.core.ActivityEntry
import java.text.SimpleDateFormat
import java.util.Locale

@Composable
fun ActivityScreen(vm: MainViewModel, padding: PaddingValues, onVerify: (Uri) -> Unit) {
    var deleting by remember { mutableStateOf<List<ActivityEntry>?>(null) }
    val allEntries by vm.activity.collectAsStateWithLifecycle()
    val savedDocuments by vm.savedDocuments.collectAsStateWithLifecycle()
    var protecting by remember { mutableStateOf(false) }
    var protectionSource by remember { mutableStateOf<Uri?>(null) }
    var decryptSource by remember { mutableStateOf(false) }
    if (protecting) FileProtectionDialog(vm, initialFile = protectionSource, initialDecrypt = decryptSource) { protecting = false; protectionSource = null }
    var history by remember { mutableStateOf(false) }
    val entries = if (history) allEntries else savedDocuments
    var confirm by remember { mutableStateOf(false) }
    var detailsEntry by remember { mutableStateOf<ActivityEntry?>(null) }
    val widgetDocument by vm.widgetDocument.collectAsStateWithLifecycle()
    LaunchedEffect(widgetDocument) {
        val id = widgetDocument ?: return@LaunchedEffect
        history = false
        detailsEntry = savedDocuments.firstOrNull { it.id == id && it.signedOutput && it.ok }
        vm.consumeWidgetDocument()
    }

    val captureIntent = LocalContext.current.hostActivity()?.intent
    val captureDialog = if (md.moldsign.app.DemoMode.screenshotCapture(captureIntent)) captureIntent?.getStringExtra("capture_dialog") else null
    LaunchedEffect(captureDialog, savedDocuments) {
        if (md.moldsign.app.DemoMode.screenshotCapture(captureIntent)) {
            protecting = captureDialog?.startsWith("protect-") == true && captureDialog != "protect-menu"
            history = captureDialog == "history" || captureDialog == "history-clear"
            confirm = captureDialog == "history-clear"
            detailsEntry = when (captureDialog) {
                "document-details" -> savedDocuments.firstOrNull { it.documentUri?.contains("contract-semnat.pdf") == true }
                "document-missing" -> savedDocuments.firstOrNull { it.documentUri?.contains("act-vechi.pdf") == true }
                else -> null
            }
        }
    }
    // "Salvează ca…": the system save dialog, one launcher per file type so the picker proposes the right extension.
    var saveSource by remember { mutableStateOf<Uri?>(null) }
    val savePdf = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/pdf")) { vm.saveCopy(saveSource, it) }
    val saveXml = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/xml")) { vm.saveCopy(saveSource, it) }
    val saveOther = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/octet-stream")) { vm.saveCopy(saveSource, it) }
    val saveAs: (String) -> Unit = { name -> when { name.endsWith(".xml", ignoreCase = true) -> saveXml.launch(name); name.endsWith(".pdf", ignoreCase = true) -> savePdf.launch(name); else -> saveOther.launch(name) } }
    LifecycleResumeEffect(Unit) {
        vm.pruneActivity()
        onPauseOrDispose { }
    }
    ScreenColumn(padding) {
        Row(Gutter.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically) {
            FilterChip(modifier = Modifier.semantics { testTagsAsResourceId = true }.testTag("documents.savedTab"), selected = !history, onClick = { history = false }, label = { Text(stringResource(R.string.saved_signed)) })
            FilterChip(modifier = Modifier.semantics { testTagsAsResourceId = true }.testTag("documents.historyTab"), selected = history, onClick = { history = true }, label = { Text(stringResource(R.string.saved_history)) })
            Spacer(Modifier.weight(1f))
            if (entries.isNotEmpty()) {
                IconButton(modifier = Modifier.semantics { testTagsAsResourceId = true }
                    .testTag(if (history) "documents.clearHistory" else "documents.deleteAll"),
                    onClick = { if (history) confirm = true else deleting = savedDocuments.toList() }) {
                    Icon(Icons.Outlined.DeleteSweep, contentDescription = stringResource(
                        if (history) R.string.activity_clear else R.string.saved_delete_all))
                }
            }
        }
        if (entries.isEmpty()) {
            Column(
                Gutter.fillMaxWidth().padding(top = Tokens.S8),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Icon(if (history) Icons.Outlined.History else Icons.Outlined.FolderOpen, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(48.dp))
                Spacer(Modifier.height(Tokens.S3))
                Text(stringResource(if (history) R.string.activity_empty_title else R.string.saved_empty), style = MaterialTheme.typography.titleMedium)
                Text(
                    stringResource(if (history) R.string.activity_empty_body else R.string.saved_hint),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                )
            }
        } else {
            Card(
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
                shape = RoundedCornerShape(Tokens.RadiusCard),
                modifier = Gutter.fillMaxWidth(),
            ) {
                entries.forEachIndexed { i, e ->
                    if (i > 0) HorizontalDivider(Modifier.padding(start = if (history) Tokens.S4 else 56.dp))
                    ActivityRow(e, onDetails = { detailsEntry = it }, onVerify = onVerify, onProtect = { uri, decrypt -> protectionSource = uri; decryptSource = decrypt; protecting = true }, onDelete = if (history) null else ({ deleting = listOf(e) }), onSaveAs = { source, name -> saveSource = source; saveAs(name) })
                }
            }
        }
    }
    deleting?.let { selected ->
        AlertDialog(
            onDismissRequest = { deleting = null },
            title = { Text(stringResource(if (selected.size == 1) R.string.saved_delete else R.string.saved_delete_all)) },
            text = { Text((if (selected.size == 1) selected.first().title + "\n\n" else "") + stringResource(R.string.saved_delete_warning)) },
            confirmButton = { TextButton(onClick = { deleting = null; vm.deleteSavedDocuments(selected) }) {
                Text(stringResource(if (selected.size == 1) R.string.saved_delete else R.string.saved_delete_all))
            } },
            dismissButton = { TextButton(onClick = { deleting = null }) { Text(stringResource(R.string.action_cancel)) } },
        )
    }
    detailsEntry?.let { entry ->
        if (entry.protectionOperation != null) ProtectedDocumentDetails(entry, onDismiss = { detailsEntry = null }, onDecrypt = {
            detailsEntry = null; protectionSource = it; decryptSource = true; protecting = true
        }) else SavedDocumentDetails(vm, entry, onDismiss = { detailsEntry = null })
    }
    if (confirm) {
        AlertDialog(
            onDismissRequest = { confirm = false },
            icon = { Icon(Icons.Outlined.DeleteSweep, contentDescription = null) },
            title = { Text(stringResource(R.string.activity_clear_title)) },
            text = { Text(stringResource(R.string.activity_clear_body)) },
            confirmButton = {
                TextButton(modifier = Modifier.semantics { testTagsAsResourceId = true }.testTag("documents.clearHistory.confirm"), onClick = {
                    confirm = false
                    vm.clearActivity()
                }) { Text(stringResource(R.string.activity_clear_confirm)) }
            },
            dismissButton = { TextButton(modifier = Modifier.semantics { testTagsAsResourceId = true }.testTag("documents.clearHistory.cancel"), onClick = { confirm = false }) { Text(stringResource(R.string.action_cancel)) } },
        )
    }
}

@Composable
private fun ActivityRow(e: ActivityEntry, onDetails: (ActivityEntry) -> Unit, onVerify: (Uri) -> Unit, onDelete: (() -> Unit)? = null, onProtect: (Uri, Boolean) -> Unit, onSaveAs: (source: Uri, name: String) -> Unit) {
    val context = LocalContext.current
    val colors = LocalStatusColors.current
    val uri = e.documentUri?.toUri()?.takeIf { it.scheme == "content" }
    var menu by remember(e.id) { mutableStateOf(false) }
    val statusIcon: @Composable () -> Unit = {
        when {
            e.kind == ActivityEntry.Kind.Browser -> Icon(Icons.Outlined.Language, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
            e.protectionOperation == "encrypt" -> Icon(Icons.Outlined.Lock, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
            e.protectionOperation == "decrypt" -> Icon(Icons.Outlined.FolderOpen, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
            e.ok -> Icon(Icons.Outlined.CheckCircle, contentDescription = null, tint = colors.success)
            else -> Icon(Icons.Outlined.ErrorOutline, contentDescription = null, tint = colors.danger)
        }
    }
    val description = when (e.protectionOperation) {
        "encrypt" -> stringResource(R.string.protect_encrypted)
        "decrypt" -> stringResource(R.string.protect_decrypted)
        else -> signatureLabels(e.subtitle)
    }
    val rowModifier = if (e.documentUri != null) Modifier.clickable(onClickLabel = stringResource(R.string.saved_details)) { onDetails(e) } else Modifier
    val actions: @Composable () -> Unit = {
    Row(verticalAlignment = Alignment.CenterVertically) {
        if (onDelete != null && uri != null) DocumentShareButton(uri, e.title)
        if (onDelete != null || uri != null) {
            Box {
                IconButton(onClick = { menu = true }) {
                    Icon(Icons.Outlined.MoreVert, contentDescription = stringResource(R.string.action_more))
                }
                DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                    if (uri != null) {
                        DropdownMenuItem(text = { Text(stringResource(R.string.action_open)) }, onClick = { menu = false; context.openDocument(uri, e.title) })
                        if (e.protectionOperation == "encrypt") DropdownMenuItem(text = { Text(stringResource(R.string.protect_decrypt)) }, onClick = { menu = false; onProtect(uri, true) })
                        else DropdownMenuItem(text = { Text(stringResource(R.string.nav_verify)) }, onClick = { menu = false; onVerify(uri) })
                        DropdownMenuItem(text = { Text(stringResource(R.string.protect_title)) }, onClick = { menu = false; onProtect(uri, false) })
                        if (onDelete == null) DropdownMenuItem(text = { Text(stringResource(R.string.action_share)) }, onClick = { menu = false; context.shareDocument(uri, e.title) })
                        DropdownMenuItem(text = { Text(stringResource(R.string.action_save_as)) }, onClick = { menu = false; onSaveAs(uri, e.title) })
                    }
                    onDelete?.let { remove ->
                        DropdownMenuItem(text = { Text(stringResource(R.string.saved_delete)) }, onClick = { menu = false; remove() })
                    }
                }
            }
        }
    }
    }
    if (onDelete == null) {
        val locale = LocalConfiguration.current.locales.get(0)
        val date = remember(locale) { java.text.DateFormat.getDateTimeInstance(java.text.DateFormat.MEDIUM, java.text.DateFormat.SHORT, locale) }
        Column(rowModifier.fillMaxWidth().padding(horizontal = Tokens.S4, vertical = Tokens.S2)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                statusIcon()
                Text(date.format(java.util.Date(e.timeMillis)), style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.weight(1f))
                actions()
            }
            Text(e.title, style = MaterialTheme.typography.titleMedium)
            Text(description, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 4.dp, bottom = 8.dp))
        }
        return
    }
    ListItem(
        leadingContent = statusIcon,
        headlineContent = { Text(e.title, maxLines = 2, overflow = TextOverflow.Ellipsis) },
        supportingContent = { Text(activityTime(e.timeMillis) + "  ·  " + description, maxLines = 2, overflow = TextOverflow.Ellipsis) },
        trailingContent = actions,
        colors = ListItemDefaults.colors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
        modifier = rowModifier,
    )
}

/** Protection results are ordinary files, not signature-verification results. */
@Composable
private fun ProtectedDocumentDetails(entry: ActivityEntry, onDismiss: () -> Unit, onDecrypt: (Uri) -> Unit) {
    val uri = entry.documentUri?.toUri()?.takeIf { it.scheme == "content" }
    val encrypted = entry.protectionOperation == "encrypt"
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(entry.title) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(stringResource(if (encrypted) R.string.protect_encrypted else R.string.protect_decrypted))
                if (uri != null) DocumentDetailActions(uri, entry.title, if (encrypted) ({ onDecrypt(uri) }) else null)
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.action_close)) } },
    )
}

/** Current verification details, not the historic signing outcome. Does not mutate the Verify tab. */
@Composable
private fun SavedDocumentDetails(vm: MainViewModel, entry: ActivityEntry, onDismiss: () -> Unit) {
    val context = LocalContext.current
    val unavailableMessage by rememberUpdatedState(stringResource(R.string.saved_unavailable))
    var detached by remember(entry.id) { mutableStateOf<List<Uri>>(emptyList()) }
    var originalSelection by remember(entry.id) { mutableIntStateOf(0) }
    var outcome by remember(entry.id) { mutableStateOf<VerifyOutcome?>(null) }
    var error by remember(entry.id) { mutableStateOf<String?>(null) }
    var loading by remember(entry.id) { mutableStateOf(true) }
    val attach = rememberLauncherForActivityResult(ActivityResultContracts.OpenMultipleDocuments()) { uris ->
        val next = (detached.filterNot { it in uris } + uris).distinct()
        if (uris.isNotEmpty()) {
            // Stop showing the previous verdict immediately, before the new effect starts.
            outcome = null
            error = null
            loading = true
            detached = next
            originalSelection++
        }
    }
    LaunchedEffect(entry.id, detached, originalSelection) {
        loading = true
        outcome = null
        error = null
        val companions = detached
        try {
            val checked = vm.inspectSavedDocument(requireNotNull(entry.documentUri).toUri(), companions)
            if (detached == companions) outcome = checked
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            // Saved-file access failures must not expose internal paths or provider exception text.
            if (detached == companions) error = unavailableMessage
        }
        // A cancelled/obsolete read must not turn off a newer request's loading indicator.
        if (detached == companions) loading = false
        if (md.moldsign.app.DemoMode.screenshotCapture(context.hostActivity()?.intent)) {
            android.util.Log.i("MoldSignDemo", "capture-ready:activity")
        }
    }
    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Surface(
            modifier = Modifier.padding(Tokens.S4).widthIn(max = 680.dp).fillMaxWidth()
                .heightIn(max = LocalConfiguration.current.screenHeightDp.dp * 0.9f),
            shape = RoundedCornerShape(Tokens.RadiusCard),
            tonalElevation = 6.dp,
        ) {
            Column {
                Row(Modifier.fillMaxWidth().padding(horizontal = Tokens.S4), verticalAlignment = Alignment.CenterVertically) {
                    Text(stringResource(R.string.saved_details), style = MaterialTheme.typography.titleLarge, modifier = Modifier.weight(1f))
                    TextButton(onClick = onDismiss) { Text(stringResource(R.string.action_close)) }
                }
                HorizontalDivider()
                Column(
                    Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()).padding(Tokens.S4),
                    verticalArrangement = Arrangement.spacedBy(Tokens.S3),
                ) {
                    Text(entry.title, style = MaterialTheme.typography.titleMedium)
                    if (loading) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(Tokens.S3)) {
                            CircularProgressIndicator(Modifier.size(24.dp))
                            Text(stringResource(R.string.saved_loading))
                        }
                    }
                    error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
                    outcome?.let { result ->
                        VerdictBadge(result)
                        if (result.missingDocuments.isNotEmpty()) {
                            MissingDocuments(result.missingDocuments) { attach.launch(arrayOf("*/*")) }
                        }
                        result.reports.forEach { SignatureCard(it) }
                    }
                }
                val uri = entry.documentUri?.toUri()
                if (outcome != null && uri?.scheme == "content") {
                    HorizontalDivider()
                    Box(Modifier.padding(horizontal = Tokens.S4, vertical = Tokens.S2)) {
                        DocumentDetailActions(uri, entry.title)
                    }
                }
            }
        }
    }
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
