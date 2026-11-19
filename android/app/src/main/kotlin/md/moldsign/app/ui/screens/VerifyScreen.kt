package md.moldsign.app.ui.screens

import md.moldsign.app.hostActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.draganddrop.DragAndDropEvent
import androidx.compose.ui.draganddrop.DragAndDropTarget
import androidx.compose.foundation.draganddrop.dragAndDropTarget
import androidx.compose.ui.draganddrop.toAndroidDragEvent
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import md.moldsign.app.presentation.MainViewModel
import md.moldsign.app.R
import md.moldsign.app.ui.components.DocumentPickZone
import androidx.compose.ui.unit.dp
import androidx.compose.runtime.key
import md.moldsign.app.application.PickedDocument
import md.moldsign.app.application.VerifyOutcome
import md.moldsign.app.ui.theme.Tokens

@OptIn(androidx.compose.ui.ExperimentalComposeUiApi::class)
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

    val choose = { picker.launch(arrayOf("application/pdf", "text/xml", "application/xml")) }
    val hasDocuments = verifiedDocuments.isNotEmpty() || doc != null
    Column(Modifier.fillMaxSize().padding(padding).semantics { testTagsAsResourceId = true }
        .dragAndDropTarget(shouldStartDragAndDrop = { true }, target = dropTarget),
        horizontalAlignment = Alignment.CenterHorizontally) {
        Box(Modifier.weight(1f).fillMaxWidth()) {
            ScreenColumn(PaddingValues(0.dp)) {
                Column(Gutter, verticalArrangement = Arrangement.spacedBy(Tokens.S4)) {
                    val current = doc
                    if (verifiedDocuments.isEmpty() && current == null) {
                        DocumentPickZone(onPick = choose, title = stringResource(R.string.action_choose_document),
                            body = stringResource(R.string.verify_hint))
                    } else {
                        if (current != null) key(current.uri) {
                            VerificationFile(current, outcome, onRemove = vm::clearVerifyDoc,
                                onAttach = { attach.launch(arrayOf("*/*")) })
                        }
                        verifiedDocuments.filter { it.first.uri != current?.uri }.forEach { (document, result) ->
                            key(document.uri) {
                                HorizontalDivider()
                                VerificationFile(document, result, onRemove = { vm.removeVerifiedDocument(document.uri) })
                            }
                        }
                    }
                }
            }
        }
        Surface(color = MaterialTheme.colorScheme.surface) {
            Button(onClick = choose, modifier = Modifier.widthIn(max = 680.dp).fillMaxWidth()
                .padding(horizontal = 24.dp, vertical = 12.dp).heightIn(min = 56.dp)
                .testTag("verify.pickFiles")) {
                Text(stringResource(if (hasDocuments) R.string.verify_choose_another else R.string.guided_choose),
                    style = MaterialTheme.typography.titleMedium,
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center)
            }
        }
    }
}

@Composable
private fun VerificationFile(document: PickedDocument, outcome: VerifyOutcome?, onRemove: () -> Unit,
                             onAttach: (() -> Unit)? = null) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Text(document.name, style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f))
        IconButton(onClick = onRemove) { Icon(Icons.Outlined.Close, contentDescription = stringResource(R.string.action_remove)) }
    }
    outcome?.let { result ->
        VerdictBadge(result)
        if (result.missingDocuments.isNotEmpty() && onAttach != null) MissingDocuments(result.missingDocuments, onAttach)
        result.reports.forEach { SignatureCard(it) }
    }
}
