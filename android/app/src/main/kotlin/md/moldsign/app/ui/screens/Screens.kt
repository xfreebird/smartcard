package md.moldsign.app.ui.screens

import md.moldsign.app.hostActivity

import md.moldsign.app.ui.components.signatureLabels
import md.moldsign.app.ui.components.CertificateLabels

import android.Manifest
import androidx.compose.material.icons.outlined.FolderOpen
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.FilterChip
import android.content.Intent
import android.net.Uri
import android.app.Activity
import androidx.annotation.StringRes
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.relocation.BringIntoViewRequester
import androidx.compose.foundation.relocation.bringIntoViewRequester
import androidx.compose.foundation.clickable
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.widthIn
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
import androidx.compose.material.icons.rounded.Draw
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
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.draganddrop.DragAndDropEvent
import androidx.compose.ui.draganddrop.DragAndDropTarget
import androidx.compose.foundation.draganddrop.dragAndDropTarget
import androidx.compose.ui.draganddrop.toAndroidDragEvent
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.pluralStringResource
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
import md.moldsign.app.presentation.errorText
import md.moldsign.app.presentation.statusLabel
import md.moldsign.app.presentation.stepText
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

/** A bounded reading width on large windows; destination content keeps native nonzero gutters. */
@Composable
private fun ScreenColumn(padding: PaddingValues, fullWidth: Boolean = false, content: @Composable ColumnScope.() -> Unit) {
    Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.TopCenter) {
        Column(
            Modifier
                .then(if (fullWidth) Modifier else Modifier.widthIn(max = 680.dp))
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(vertical = Tokens.S3),
            verticalArrangement = Arrangement.spacedBy(Tokens.S4),
            horizontalAlignment = Alignment.CenterHorizontally,
            content = content,
        )
    }
}

private val Gutter = Modifier.padding(horizontal = Tokens.S4)

@Composable
private fun SectionHeader(title: String, modifier: Modifier = Gutter, action: (@Composable () -> Unit)? = null) {
    Row(modifier.fillMaxWidth().heightIn(min = 48.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(title, style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.weight(1f))
        action?.invoke()
    }
}

/** Wide windows keep the identity and document workflow visible in independently scrolling panes. */
@Composable
fun SignScreen(vm: MainViewModel, padding: PaddingValues, onOpenCard: () -> Unit, onOpenDocuments: () -> Unit, expanded: Boolean = false) {
    val context = LocalContext.current
    val signDropTarget = remember(vm) {
        object : DragAndDropTarget {
            override fun onDrop(event: DragAndDropEvent): Boolean {
                val native = event.toAndroidDragEvent()
                val uris = native.clipData?.let { clip -> (0 until clip.itemCount).mapNotNull { clip.getItemAt(it).uri } }.orEmpty()
                if (uris.isEmpty()) return false
                val permission = context.hostActivity()?.requestDragAndDropPermissions(native)
                vm.receiveDroppedForSigning(uris) { permission?.release() }
                return true
            }
        }
    }
    val liveStatus by vm.status.collectAsStateWithLifecycle()
    val captureIntent = context.hostActivity()?.intent
    val captureStep = if (md.moldsign.app.DemoMode.screenshotCapture(captureIntent))
        SigningStep.entries.firstOrNull { it.name == captureIntent?.getStringExtra("capture_step") } else null
    val status = if (captureStep != null) liveStatus.copy(light = md.moldsign.core.StatusLight.Busy, busy = true) else liveStatus
    val signedResults by vm.signedResults.collectAsStateWithLifecycle()
    val items by vm.signItems.collectAsStateWithLifecycle()
    val liveProgress by vm.progress.collectAsStateWithLifecycle()
    val liveWorking by vm.working.collectAsStateWithLifecycle()
    val progress = captureStep ?: liveProgress
    val working = liveWorking || captureStep != null
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.OpenMultipleDocuments()) { vm.addForSigning(it) }
    val canSign = items.isNotEmpty() && status.wallet.selectedCard?.isReady == true && !status.busy && !working
    val pick = { picker.launch(arrayOf("*/*")) }
    var editingStamp by remember { mutableStateOf<md.moldsign.app.application.SignItem?>(null) }
    var editingBatchStamp by remember { mutableStateOf(false) }
    var previewOpened by remember { mutableStateOf(false) }
    LaunchedEffect(items) {
        if (!previewOpened && md.moldsign.app.DemoMode.stampPreview && items.isNotEmpty()) {
            previewOpened = true
            editingStamp = items.first()
        }
    }
    editingStamp?.let { item -> PdfStampEditor(item, holder = status.wallet.selectedCard?.certificate?.commonName ?: "", onDismiss = { editingStamp = null },
        onSave = { stamp -> if (editingBatchStamp) vm.setBatchStamp(item, stamp) else vm.setStamp(item, stamp); editingStamp = null }, requester = if (editingBatchStamp) stringResource(R.string.batch_stamp) else null, onBatch = if (editingBatchStamp) null else { stamp -> vm.setBatchStamp(item, stamp) }) }

    val walletContent: @Composable () -> Unit = {
        CardWallet(
            status.wallet,
            onSelect = vm::selectCard,
            onReread = vm::rereadCards,
            onAllowUsb = vm::requestUsbPermission,
            onOpen = onOpenCard,
            selectionEnabled = !status.busy,
        )
    }
    val documentContent: @Composable () -> Unit = {
        Column {
            SectionHeader(stringResource(R.string.sign_documents), modifier = if (expanded) Modifier else Gutter)
            Column(if (expanded) Modifier else Gutter, verticalArrangement = Arrangement.spacedBy(Tokens.S3)) {
                if (items.isEmpty()) {
                    DocumentPickZone(onPick = pick, compact = LocalConfiguration.current.screenHeightDp < 400)
                } else {
                    DocumentList(items, onFormat = vm::setFormat, onRemove = vm::remove, onRetry = vm::retry, retryEnabled = !working, onStamp = { editingBatchStamp = false; editingStamp = it }, onBatchStamp = { editingBatchStamp = true; editingStamp = it }, onRemoveGroup = vm::removeGroup)
                    if (!canSign && !working) SignBlockedHint(statusLabel(LocalContext.current, status))
                    DocumentAddTile(onPick = pick)
                }
            }
        }
    }

    val resultContent: @Composable () -> Unit = {
        val context = LocalContext.current
        if (signedResults.isNotEmpty()) {
            Column((if (expanded) Modifier.widthIn(max = 680.dp).fillMaxWidth() else Gutter)
                .background(MaterialTheme.colorScheme.surfaceContainerLow, RoundedCornerShape(20.dp)).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(Tokens.S3)) {
                Column(Modifier.fillMaxWidth()) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Outlined.CheckCircle, contentDescription = null, tint = LocalStatusColors.current.success)
                        Spacer(Modifier.width(8.dp))
                        Text(stringResource(R.string.saved_signed), style = MaterialTheme.typography.titleMedium)
                    }
                    TextButton(onClick = vm::clearSignedResults, enabled = !working, modifier = Modifier.align(Alignment.End)) { Text(stringResource(R.string.results_clear)) }
                }
                signedResults.forEach { (name, uri) ->
                    Card(onClick = {
                        runCatching { context.startActivity(Intent(Intent.ACTION_VIEW).setDataAndType(uri, mimeOf(name))
                            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)) }
                    }, modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(Tokens.RadiusCard)) {
                        Row(Modifier.fillMaxWidth().padding(Tokens.S4), verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(Tokens.S3)) {
                            Icon(Icons.Outlined.CheckCircle, contentDescription = null, tint = LocalStatusColors.current.success)
                            Text(name, modifier = Modifier.weight(1f), style = MaterialTheme.typography.bodyMedium)
                            Text(stringResource(R.string.action_open), style = MaterialTheme.typography.labelLarge)
                            Icon(Icons.AutoMirrored.Outlined.OpenInNew, contentDescription = null)
                        }
                    }
                }
                Text(stringResource(R.string.results_hint), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                OutlinedButton(onClick = onOpenDocuments, modifier = Modifier.fillMaxWidth()) {
                    Icon(Icons.Outlined.FolderOpen, contentDescription = null)
                    Spacer(Modifier.width(8.dp))
                    Text(stringResource(R.string.results_documents))
                }
            }
        }
    }

    val signAction: @Composable () -> Unit = {
        if (items.isNotEmpty()) {
            Button(onClick = vm::sign, enabled = canSign, modifier = Modifier.heightIn(min = 48.dp)) {
                Icon(Icons.Rounded.Draw, contentDescription = null, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(Tokens.S2))
                Text(pluralStringResource(R.plurals.sign_n, items.size, items.size))
            }
        }
    }
    BoxWithConstraints(Modifier.fillMaxSize().dragAndDropTarget(shouldStartDragAndDrop = { true }, target = signDropTarget)) {
    val shortWindow = maxHeight < 360.dp
    val sideBySide = expanded && maxWidth >= 700.dp && maxWidth > maxHeight
    if (sideBySide) {
        Row(Modifier.fillMaxSize().padding(padding).padding(16.dp), horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            Column(Modifier.weight(0.42f).fillMaxHeight().verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(Tokens.S4), horizontalAlignment = Alignment.CenterHorizontally) {
                walletContent()
                if (working) StepCard(progress, modifier = Modifier)
            }
            Column(Modifier.weight(0.58f).fillMaxHeight().verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(Tokens.S4), horizontalAlignment = Alignment.CenterHorizontally) {
                resultContent()
                documentContent()
                signAction()
            }
        }
    } else if (expanded) {
        Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.TopCenter) {
            Column(
                Modifier.fillMaxWidth()
                    .verticalScroll(rememberScrollState()).padding(if (shortWindow) 8.dp else 24.dp),
                verticalArrangement = Arrangement.spacedBy(Tokens.S4),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                if (!shortWindow) walletContent()
                if (working) StepCard(progress, modifier = Modifier)
                resultContent()
                Box(Modifier.widthIn(max = 680.dp).fillMaxWidth()) { documentContent() }
                if (shortWindow) walletContent()
                if (items.isNotEmpty()) {
                    Button(
                        onClick = vm::sign,
                        enabled = canSign,
                        modifier = Modifier.heightIn(min = 48.dp),
                    ) {
                        Icon(Icons.Rounded.Draw, contentDescription = null, modifier = Modifier.size(20.dp))
                        Spacer(Modifier.width(Tokens.S2))
                        Text(pluralStringResource(R.plurals.sign_n, items.size, items.size))
                    }
                }
            }
        }
    } else {
        ScreenColumn(padding) {
            walletContent()
            if (working) StepCard(progress)
            resultContent()
            documentContent()
            Spacer(Modifier.height(72.dp)) // keep the phone's floating action clear of the final document
        }
    }
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
private fun StepCard(step: SigningStep, modifier: Modifier = Gutter) {
    val context = LocalContext.current
    val captureIntent = context.hostActivity()?.intent
    val captureProgress = md.moldsign.app.DemoMode.screenshotCapture(captureIntent) && captureIntent?.hasExtra("capture_step") == true
    val capturePosition = remember { BringIntoViewRequester() }
    LaunchedEffect(captureProgress, step) {
        if (captureProgress) {
            androidx.compose.runtime.withFrameNanos { }
            capturePosition.bringIntoView()
            android.util.Log.i("MoldSignDemo", "capture-scroll-ready:sign")
        }
    }
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.secondaryContainer),
        shape = RoundedCornerShape(Tokens.RadiusCard),
        modifier = modifier.fillMaxWidth().bringIntoViewRequester(capturePosition),
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
    val context = LocalContext.current
    val verifiedDocuments by vm.verifiedDocuments.collectAsStateWithLifecycle()
    val doc by vm.verifyDoc.collectAsStateWithLifecycle()
    val outcome by vm.verifyOutcome.collectAsStateWithLifecycle()
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.OpenMultipleDocuments()) { vm.pickMultipleForVerify(it) }
    val attach = rememberLauncherForActivityResult(ActivityResultContracts.OpenMultipleDocuments()) { vm.addVerifyDocuments(it) }
    val dropTarget = remember(vm) {
        object : DragAndDropTarget {
            override fun onDrop(event: DragAndDropEvent): Boolean {
                val androidEvent = event.toAndroidDragEvent()
                val uris = androidEvent.clipData?.let { clip ->
                    (0 until clip.itemCount).mapNotNull { index -> clip.getItemAt(index).uri }
                }.orEmpty()
                if (uris.isEmpty()) return false
                val permission = context.hostActivity()?.requestDragAndDropPermissions(androidEvent)
                vm.receiveDroppedForVerify(uris) { permission?.release() }
                return true
            }
        }
    }

    ScreenColumn(padding) {
        Column(Gutter.dragAndDropTarget(shouldStartDragAndDrop = { true }, target = dropTarget), verticalArrangement = Arrangement.spacedBy(Tokens.S4)) {
            if (verifiedDocuments.isNotEmpty() || doc != null) {
                TextButton(onClick = vm::clearVerifyResults) { Text(stringResource(R.string.clear_results)) }
            }
            verifiedDocuments.filter { it.first.uri != doc?.uri }.forEach { (document, result) ->
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Text(document.name, modifier = Modifier.weight(1f), style = MaterialTheme.typography.titleMedium)
                    TextButton(onClick = { vm.removeVerifiedDocument(document.uri) }) { Text(stringResource(R.string.action_remove)) }
                }
                VerdictBadge(result)
                result.reports.forEach { SignatureCard(it) }
            }
            val current = doc
            DocumentPickZone(onPick = { picker.launch(arrayOf("application/pdf", "text/xml", "application/xml")) }, title = stringResource(R.string.action_choose_document), body = stringResource(R.string.verify_hint))
            if (current != null) {
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
    val captureIntent = LocalContext.current.hostActivity()?.intent
    val captureTarget = md.moldsign.app.DemoMode.screenshotCapture(captureIntent) &&
        captureIntent?.getStringExtra("demo")?.startsWith("verify-") == true &&
        captureIntent.getStringExtra("demo") != "verify-xml-missing" && captureIntent.getStringExtra("capture_expand") == null
    val capturePosition = remember { BringIntoViewRequester() }
    LaunchedEffect(captureTarget) {
        if (captureTarget) {
            androidx.compose.runtime.withFrameNanos { }
            capturePosition.bringIntoView()
            android.util.Log.i("MoldSignDemo", "capture-scroll-ready:verify")
        }
    }
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
        modifier = Modifier.fillMaxWidth().bringIntoViewRequester(capturePosition),
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
    val captureIntent = LocalContext.current.hostActivity()?.intent
    val captureTarget = md.moldsign.app.DemoMode.screenshotCapture(captureIntent) && captureIntent?.getStringExtra("demo") == "verify-xml-missing"
    val capturePosition = remember { BringIntoViewRequester() }
    LaunchedEffect(captureTarget) {
        if (captureTarget) {
            androidx.compose.runtime.withFrameNanos { }
            capturePosition.bringIntoView()
            android.util.Log.i("MoldSignDemo", "capture-scroll-ready:verify")
        }
    }
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
        shape = RoundedCornerShape(Tokens.RadiusCard),
        modifier = Modifier.fillMaxWidth().bringIntoViewRequester(capturePosition),
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
    val captureIntent = LocalContext.current.hostActivity()?.intent
    val captureExpand = if (md.moldsign.app.DemoMode.screenshotCapture(captureIntent)) captureIntent?.getStringExtra("capture_expand") else null
    var certificateExpanded by remember(captureExpand) { mutableStateOf(captureExpand == "certificate") }
    var details by remember(captureExpand) { mutableStateOf(captureExpand == "technical") }
    val locale = androidx.compose.ui.platform.LocalConfiguration.current.locales.get(0)
    val dateTime = remember(locale) { DateFormat.getDateTimeInstance(DateFormat.MEDIUM, DateFormat.SHORT, locale) }
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
        shape = RoundedCornerShape(Tokens.RadiusCard),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(Modifier.padding(Tokens.S4), verticalArrangement = Arrangement.spacedBy(Tokens.S2)) {
            Text(stringResource(R.string.sig_author, report.signerName ?: stringResource(R.string.sig_unknown_signer)), style = MaterialTheme.typography.titleMedium)
            Text(stringResource(R.string.sig_signature), style = MaterialTheme.typography.labelLarge)
            report.signerIdnp?.let { Text("IDNP: $it") }
            report.level?.let { Text(signatureLabels(it), style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant) }
            report.signingTime?.let { Text(stringResource(R.string.sig_signed_at, dateTime.format(it)), style = MaterialTheme.typography.bodyMedium) }
            report.timestampTime?.let { Text(stringResource(R.string.sig_timestamp, dateTime.format(it)), style = MaterialTheme.typography.bodyMedium) }
            FlowRow(horizontalArrangement = Arrangement.spacedBy(Tokens.S2), verticalArrangement = Arrangement.spacedBy(Tokens.S2)) {
                CheckChip(R.string.sig_integrity, if (report.missingDocuments.isNotEmpty()) null else report.integrityOk)
                CheckChip(R.string.sig_signature, report.signatureOk)
                CheckChip(R.string.sig_chain, report.chainOk)
            }
            if (report.certificateDetails.isNotEmpty()) {
                TextButton(onClick = { certificateExpanded = !certificateExpanded }, modifier = Modifier.fillMaxWidth()) { Text(stringResource(R.string.sig_certificate_details)) }
                if (certificateExpanded) report.certificateDetails.forEach { (key, value) ->
                    Text("${CertificateLabels.label(key)}: $value", style = MaterialTheme.typography.bodySmall)
                }
            }
            if (report.details.isNotEmpty()) {
                TextButton(onClick = { details = !details }, modifier = Modifier.fillMaxWidth(), contentPadding = PaddingValues(horizontal = 0.dp)) {
                    Text(stringResource(R.string.sig_details))
                    Icon(if (details) Icons.Outlined.ExpandLess else Icons.Outlined.ExpandMore, contentDescription = null)
                }
                if (details) {
                    Text(signatureLabels(report.details.joinToString("\n")), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
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
 * Independent saved-output library and clearable activity history. Only history is pruned on resume;
 * unavailable saved outputs remain visible and report the access error in their details sheet.
 */
@Composable
fun ActivityScreen(vm: MainViewModel, padding: PaddingValues, onVerify: (Uri) -> Unit) {
    val allEntries by vm.activity.collectAsStateWithLifecycle()
    val savedDocuments by vm.savedDocuments.collectAsStateWithLifecycle()
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
    val saveAs: (String) -> Unit = { name -> if (name.endsWith(".xml", ignoreCase = true)) saveXml.launch(name) else savePdf.launch(name) }
    LifecycleResumeEffect(Unit) {
        vm.pruneActivity()
        onPauseOrDispose { }
    }
    ScreenColumn(padding) {
        Row(Gutter.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            FilterChip(selected = !history, onClick = { history = false }, label = { Text(stringResource(R.string.saved_signed)) })
            FilterChip(selected = history, onClick = { history = true }, label = { Text(stringResource(R.string.saved_history)) })
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
            Column {
                SectionHeader(stringResource(if (history) R.string.activity_recent else R.string.saved_signed)) {
                    if (history) TextButton(onClick = { confirm = true }) {
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
                        ActivityRow(e, onDetails = { detailsEntry = it }, onVerify = onVerify, onSaveAs = { source, name -> saveSource = source; saveAs(name) })
                    }
                }
            }
        }
    }
    detailsEntry?.let { entry ->
        SavedDocumentDetails(vm, entry, onDismiss = { detailsEntry = null })
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
private fun ActivityRow(e: ActivityEntry, onDetails: (ActivityEntry) -> Unit, onVerify: (Uri) -> Unit, onSaveAs: (source: Uri, name: String) -> Unit) {
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
        supportingContent = { Text(signatureLabels(e.subtitle), maxLines = 2, overflow = TextOverflow.Ellipsis) },
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
                            DropdownMenuItem(text = { Text(stringResource(R.string.nav_verify)) }, onClick = { menu = false; onVerify(uri) })
                            DropdownMenuItem(text = { Text(stringResource(R.string.action_share)) }, onClick = { menu = false; share() })
                            DropdownMenuItem(text = { Text(stringResource(R.string.action_save_as)) }, onClick = { menu = false; onSaveAs(uri, e.title) })
                        }
                    }
                }
            }
        },
        colors = ListItemDefaults.colors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
        modifier = if (e.documentUri != null) Modifier.clickable(onClickLabel = stringResource(R.string.saved_details)) { onDetails(e) } else Modifier,
    )
}

/** Current verification details, not the historic signing outcome. Does not mutate the Verify tab. */
@Composable
private fun SavedDocumentDetails(vm: MainViewModel, entry: ActivityEntry, onDismiss: () -> Unit) {
    val context = LocalContext.current
    var detached by remember(entry.id) { mutableStateOf<List<Uri>>(emptyList()) }
    var outcome by remember(entry.id) { mutableStateOf<VerifyOutcome?>(null) }
    var error by remember(entry.id) { mutableStateOf<String?>(null) }
    var loading by remember(entry.id) { mutableStateOf(true) }
    val attach = rememberLauncherForActivityResult(ActivityResultContracts.OpenMultipleDocuments()) { uris ->
        val next = (detached + uris).distinct()
        if (next != detached) {
            // Stop showing the previous verdict immediately, before the new effect starts.
            outcome = null
            error = null
            loading = true
            detached = next
        }
    }
    LaunchedEffect(entry.id, detached) {
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
            if (detached == companions) error = context.getString(R.string.saved_unavailable)
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
@Composable
fun BrowserScreen(vm: MainViewModel, padding: PaddingValues, onOpenCard: () -> Unit) {
    val running by vm.bridgeRunning.collectAsStateWithLifecycle()
    val startupFailed by vm.bridgeStartupFailed.collectAsStateWithLifecycle()
    val wallet by vm.status.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val status = LocalStatusColors.current
    val notifications = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { vm.setBridge(true) }
    val captureIntent = context.hostActivity()?.intent
    val captureBrowser = md.moldsign.app.DemoMode.screenshotCapture(captureIntent) && captureIntent?.getStringExtra("capture_dialog") == "browser-window"
    var inAppBrowser by remember(captureBrowser) { mutableStateOf(captureBrowser) }
    LaunchedEffect(vm.demoMode) { if (vm.demoMode) inAppBrowser = false }
    if (inAppBrowser && !vm.demoMode) {
        InAppBrowser(onClose = { inAppBrowser = false })
        return
    }

    ScreenColumn(padding, fullWidth = true) {
        CardWallet(
            wallet.wallet,
            selectionEnabled = !wallet.busy,
            onSelect = vm::selectCard,
            onReread = vm::rereadCards,
            onAllowUsb = vm::requestUsbPermission,
            onOpen = onOpenCard,
        )
        Column(Modifier.widthIn(max = 680.dp).fillMaxWidth().then(Gutter), verticalArrangement = Arrangement.spacedBy(Tokens.S4)) {
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
                            stringResource(if (startupFailed) R.string.browser_bridge_failed else if (running) R.string.bridge_on else R.string.bridge_off),
                            color = if (startupFailed) MaterialTheme.colorScheme.error else if (running) status.success else MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    },
                    trailingContent = {
                        Switch(
                            checked = running,
                            enabled = !vm.demoMode,
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
            md.moldsign.app.ui.components.GovernmentDisclosureLink()
            Button(onClick = { inAppBrowser = true }, enabled = !vm.demoMode, modifier = Modifier.fillMaxWidth()) {
                Text(stringResource(R.string.browser_open_in_app))
            }
            FilledTonalButton(
                onClick = { context.startActivity(Intent(Intent.ACTION_VIEW, "https://msign.gov.md".toUri())) },
                enabled = !vm.demoMode,
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
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun CardScreen(vm: MainViewModel, padding: PaddingValues) {
    val status by vm.status.collectAsStateWithLifecycle()
    val wallet = status.wallet
    ScreenColumn(padding, fullWidth = true) {
        CardWallet(wallet, onSelect = vm::selectCard, onReread = vm::rereadCards, onAllowUsb = vm::requestUsbPermission, large = true, selectionEnabled = !status.busy)
        Column(Modifier.widthIn(max = 680.dp).fillMaxWidth().then(Gutter), verticalArrangement = Arrangement.spacedBy(Tokens.S3)) {
            val card = wallet.selectedCard
            if (card != null) CardDetails(card)
            FlowRow(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(Tokens.S2), verticalArrangement = Arrangement.spacedBy(Tokens.S2)) {
                FilledTonalButton(onClick = vm::rereadCards, enabled = wallet.cards.isNotEmpty() && !status.busy) {
                    Icon(Icons.Rounded.Refresh, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(Tokens.S2))
                    Text(stringResource(R.string.action_reread))
                }
                TextButton(onClick = vm::deleteStoredPin, enabled = card?.certificate != null && !vm.demoMode) {
                    Text(stringResource(R.string.pin_stored_delete))
                }
            }
            if (wallet.readers.isEmpty()) {
                Spacer(Modifier.height(Tokens.S2))
                ConnectionGuide()
            }
        }
    }
}

/** Shared About content for the dedicated Settings tab. */
@Composable
fun AboutContent() {
    val context = LocalContext.current
    val uriHandler = LocalUriHandler.current
    val version = remember {
        runCatching { context.packageManager.getPackageInfo(context.packageName, 0).versionName }.getOrNull().orEmpty()
    }
    Column(verticalArrangement = Arrangement.spacedBy(12.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Box(Modifier.size(72.dp).background(Color(0xFF3F6EF5))) {
            Image(painterResource(R.drawable.ic_launcher_foreground), contentDescription = null, modifier = Modifier.fillMaxSize())
        }
        Text(stringResource(R.string.app_name), style = MaterialTheme.typography.titleLarge)
        Text(stringResource(R.string.about_version, version))
        Text(stringResource(R.string.about_body), textAlign = TextAlign.Center)
        Text(stringResource(R.string.about_legal_title), style = MaterialTheme.typography.titleMedium)
        Text(stringResource(R.string.about_disclaimer_body), style = MaterialTheme.typography.bodyMedium)
        val language = androidx.compose.ui.platform.LocalConfiguration.current.locales.get(0).language
        val legalBase = "https://esemnbun.md" + if (language in listOf("ro", "ru")) "/$language" else ""
        listOf(
            R.string.about_terms to "$legalBase/terms/",
            R.string.about_privacy to "$legalBase/privacy/",
            R.string.about_disclaimer to "$legalBase/terms/",
        ).forEach { (label, url) ->
            TextButton(onClick = { uriHandler.openUri(url) }, modifier = Modifier.fillMaxWidth()) { Text(stringResource(label)) }
        }
        md.moldsign.app.ui.components.GovernmentSources()
        Text("Nicolae Ghimbovschi")
        TextButton(onClick = { uriHandler.openUri("https://esemnbun.md") }) { Text("esemnbun.md") }
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
