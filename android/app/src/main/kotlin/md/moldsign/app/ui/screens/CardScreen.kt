package md.moldsign.app.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Badge
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import md.moldsign.app.presentation.MainViewModel
import md.moldsign.app.R
import md.moldsign.app.ui.components.ChoiceRow
import md.moldsign.app.ui.components.SigningMethodPicker

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CardScreen(vm: MainViewModel, padding: PaddingValues) {
    val status by vm.status.collectAsStateWithLifecycle()
    val method by vm.signingMethod.collectAsStateWithLifecycle()
    val nfcIdentity by vm.nfcIdentity.collectAsStateWithLifecycle()
    var details by remember { mutableStateOf(false) }
    val certificate = if (method == MainViewModel.SigningMethod.NFC) nfcIdentity else status.wallet.selectedCard?.certificate
    if (details) CardDetailsSheet(vm) { details = false }
    Box(Modifier.fillMaxWidth().padding(padding), contentAlignment = Alignment.TopCenter) {
        Column(Modifier.widthIn(max = 608.dp).fillMaxWidth().verticalScroll(rememberScrollState()).padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(28.dp)) {
            SigningMethodPicker(vm, compact = true, inlineReaderCards = true)
            Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surfaceContainerLowest) {
                Column {
                    if (certificate != null) {
                        ChoiceRow(Icons.Outlined.Badge, stringResource(R.string.card_details_title), onClick = { details = true }, modifier = Modifier.testTag("card.details"))
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CardDetailsSheet(vm: MainViewModel, onDismiss: () -> Unit) {
    val status by vm.status.collectAsStateWithLifecycle()
    val method by vm.signingMethod.collectAsStateWithLifecycle()
    val identity by vm.nfcIdentity.collectAsStateWithLifecycle()
    val ids by vm.savedPinIds.collectAsStateWithLifecycle()
    val working by vm.working.collectAsStateWithLifecycle()
    val cert = if (method == MainViewModel.SigningMethod.NFC) identity else status.wallet.selectedCard?.certificate
    FocusedTaskSheet(stringResource(R.string.card_details_title), onDismiss = onDismiss) {
        cert?.let {
            CardDetails(it, readerName = if (method == MainViewModel.SigningMethod.Reader) status.wallet.selectedCard?.readerName else null)
            if (!vm.demoMode && it.sha1Hex in ids) TextButton(onClick = { vm.deletePin(it.sha1Hex) }, enabled = !working && !status.busy,
                colors = ButtonDefaults.textButtonColors(contentColor = MaterialTheme.colorScheme.error)) {
                Icon(Icons.Outlined.DeleteOutline, null, Modifier.size(18.dp))
                Spacer(Modifier.width(8.dp))
                Text(stringResource(R.string.pin_stored_delete))
            }
        }
    }
}
