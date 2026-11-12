package md.moldsign.app.ui.screens

import md.moldsign.app.presentation.toCardWalletContent

import md.moldsign.app.hostActivity
import androidx.compose.material.icons.outlined.FolderOpen
import androidx.compose.material3.OutlinedButton
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import android.content.Intent
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.relocation.BringIntoViewRequester
import androidx.compose.foundation.relocation.bringIntoViewRequester
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.widthIn
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
import androidx.compose.material.icons.automirrored.outlined.OpenInNew
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.rounded.Draw
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.draganddrop.DragAndDropEvent
import androidx.compose.ui.draganddrop.DragAndDropTarget
import androidx.compose.foundation.draganddrop.dragAndDropTarget
import androidx.compose.ui.draganddrop.toAndroidDragEvent
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import md.moldsign.app.presentation.MainViewModel
import md.moldsign.app.R
import md.moldsign.app.presentation.statusLabel
import md.moldsign.app.presentation.stepText
import md.moldsign.app.ui.components.CardWallet
import md.moldsign.app.ui.components.DocumentAddTile
import md.moldsign.app.ui.features.DocumentList
import md.moldsign.app.ui.components.DocumentPickZone
import md.moldsign.app.ui.theme.LocalStatusColors
import md.moldsign.app.ui.theme.Tokens
import md.moldsign.core.SigningStep

/** Wide windows keep the identity and document workflow visible in independently scrolling panes. */
@OptIn(androidx.compose.ui.ExperimentalComposeUiApi::class)
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
            status.wallet.toCardWalletContent(),
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
            Button(onClick = vm::sign, enabled = canSign, modifier = Modifier.heightIn(min = 48.dp).testTag("sign.submit")) {
                Icon(Icons.Rounded.Draw, contentDescription = null, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(Tokens.S2))
                Text(pluralStringResource(R.plurals.sign_n, items.size, items.size))
            }
        }
    }
    BoxWithConstraints(Modifier.fillMaxSize().semantics { testTagsAsResourceId = true }.dragAndDropTarget(shouldStartDragAndDrop = { true }, target = signDropTarget)) {
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
                signAction()
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
