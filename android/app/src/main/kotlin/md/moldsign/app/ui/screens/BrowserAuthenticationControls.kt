package md.moldsign.app.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.VpnKey
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import md.moldsign.app.R
import md.moldsign.app.presentation.MainViewModel

/** Compact entry point; embedded and external browsers share one saved preference. */
@Composable
fun BrowserAuthenticationControls(vm: MainViewModel, externalHint: Boolean = false, compact: Boolean = false) {
    if (vm.demoMode) return
    val nfc by vm.browserNfc.enabled.collectAsState()
    val card by vm.browserNfc.certificate.collectAsState()
    val known by vm.knownCards.collectAsState()
    val status by vm.status.collectAsState()
    var showingOptions by remember { mutableStateOf(false) }
    LaunchedEffect(known) { vm.browserNfc.seed(vm.nfcIdentity.value ?: known.singleOrNull()) }
    if (compact) {
        IconButton(onClick = { showingOptions = true }, enabled = !status.busy) {
            Icon(Icons.Outlined.VpnKey, stringResource(R.string.browser_authentication_method))
        }
    } else {
        TextButton(onClick = { showingOptions = true }, enabled = !status.busy) {
            Text(stringResource(R.string.browser_authentication_short))
            Spacer(Modifier.width(12.dp))
            Text(stringResource(if (nfc) R.string.browser_nfc_method else R.string.browser_reader_short))
        }
    }
    if (showingOptions) AlertDialog(
        onDismissRequest = { showingOptions = false },
        title = { Text(stringResource(R.string.browser_authentication_method)) },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf(true, false).forEach { method ->
                    val enabled = !status.busy && (!method || vm.nfcAvailable)
                    Row(Modifier.fillMaxWidth().selectable(selected = nfc == method, enabled = enabled,
                        role = Role.RadioButton, onClick = { vm.browserNfc.setEnabled(method) }),
                        verticalAlignment = Alignment.CenterVertically) {
                        RadioButton(selected = nfc == method, onClick = null, enabled = enabled)
                        Spacer(Modifier.width(8.dp))
                        Text(stringResource(if (method) R.string.browser_nfc_method else R.string.browser_nfc_reader),
                            Modifier.weight(1f).padding(vertical = 12.dp))
                    }
                }
                if (nfc) {
                    card?.let { Text(it.commonName, style = MaterialTheme.typography.titleSmall) }
                    known.forEach { identity ->
                        TextButton(onClick = { vm.browserNfc.select(identity) }, enabled = !status.busy) {
                            Text(identity.commonName)
                        }
                    }
                    TextButton(onClick = { showingOptions = false; vm.identifyBrowserCard() }, enabled = !status.busy) {
                        Text(stringResource(R.string.browser_nfc_read))
                    }
                    if (card != null) Text(stringResource(R.string.browser_nfc_ready), style = MaterialTheme.typography.bodySmall)
                }
                if (externalHint) Text(stringResource(R.string.browser_authentication_external), style = MaterialTheme.typography.bodySmall)
            }
        },
        confirmButton = {
            TextButton(onClick = { showingOptions = false }) { Text(stringResource(R.string.action_close)) }
        },
    )
}
