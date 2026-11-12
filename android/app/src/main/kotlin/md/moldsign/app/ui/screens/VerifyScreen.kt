package md.moldsign.app.ui.screens

import md.moldsign.app.hostActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.draganddrop.DragAndDropEvent
import androidx.compose.ui.draganddrop.DragAndDropTarget
import androidx.compose.foundation.draganddrop.dragAndDropTarget
import androidx.compose.ui.draganddrop.toAndroidDragEvent
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import md.moldsign.app.presentation.MainViewModel
import md.moldsign.app.R
import md.moldsign.app.ui.components.DocumentPickZone
import md.moldsign.app.ui.features.DocumentRow
import md.moldsign.app.ui.theme.Tokens

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
