package md.moldsign.app.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CreditCard
import androidx.compose.material.icons.outlined.Nfc
import androidx.compose.material.icons.outlined.VpnKey
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import md.moldsign.app.R
import md.moldsign.app.presentation.MainViewModel

/** Embedded and external browsers share one saved method and certificate selection. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BrowserAuthenticationControls(vm: MainViewModel, externalHint: Boolean = false, compact: Boolean = false) {
    if (vm.demoMode) return
    val nfc by vm.browserNfc.enabled.collectAsState()
    val card by vm.browserNfc.certificate.collectAsState()
    val known by vm.knownCards.collectAsState()
    val status by vm.status.collectAsState()
    val working by vm.working.collectAsState()
    val enabled = !status.busy && !working
    val methodLabel = stringResource(if (nfc) R.string.browser_nfc_method else R.string.browser_reader_short)
    var showingOptions by remember { mutableStateOf(false) }
    if (compact) {
        IconButton(onClick = { showingOptions = true }, enabled = enabled,
            modifier = Modifier.testTag("browser.authentication")) {
            Icon(Icons.Outlined.VpnKey, stringResource(R.string.browser_authentication_method))
        }
    } else {
        OutlinedCard(modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.outlinedCardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow)) {
            ChoiceRow(if (nfc) Icons.Outlined.Nfc else Icons.Outlined.CreditCard,
                methodLabel, caption = stringResource(R.string.browser_authentication_short),
                enabled = enabled, onClick = { showingOptions = true },
                modifier = Modifier.testTag("browser.authentication"))
        }
    }
    if (showingOptions) ModalBottomSheet(
        onDismissRequest = { showingOptions = false },
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
    ) {
        Column(Modifier.widthIn(max = 680.dp).fillMaxWidth().align(Alignment.CenterHorizontally)
            .verticalScroll(rememberScrollState()).navigationBarsPadding().padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)) {
            Text(stringResource(R.string.browser_authentication_method),
                style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.SemiBold)
            Column(Modifier.selectableGroup(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf(true, false).forEach { method ->
                    BrowserAuthenticationOption(
                        title = stringResource(if (method) R.string.browser_nfc_method else R.string.browser_nfc_reader),
                        icon = if (method) Icons.Outlined.Nfc else Icons.Outlined.CreditCard,
                        selected = nfc == method, enabled = enabled && (!method || vm.nfcAvailable),
                        onClick = { vm.browserNfc.setEnabled(method) },
                        modifier = Modifier.testTag(if (method) "browser.method.nfc" else "browser.method.reader"))
                }
            }
            if (nfc) {
                // The active certificate can also be remembered. Render one selectable row per identity.
                val identities = (listOfNotNull(card) + known).distinctBy { it.sha1Hex }
                if (identities.isNotEmpty()) {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text(stringResource(R.string.browser_nfc_saved_cards),
                            style = MaterialTheme.typography.titleSmall)
                        Column(Modifier.selectableGroup(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            identities.forEach { identity ->
                                key(identity.sha1Hex) {
                                    BrowserAuthenticationOption(title = identity.commonName,
                                        detail = "${stringResource(R.string.card_serial)}: ${identity.serialHex}",
                                        selected = identity.sha1Hex == card?.sha1Hex, enabled = enabled,
                                        onClick = { vm.selectBrowserCard(identity) },
                                        modifier = Modifier.testTag("browser.card.${identity.sha1Hex}"))
                                }
                            }
                        }
                    }
                }
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedButton(onClick = { showingOptions = false; vm.identifyBrowserCard() },
                        enabled = enabled && vm.nfcAvailable,
                        modifier = Modifier.fillMaxWidth().testTag("browser.readNfc")) {
                        Icon(Icons.Outlined.Nfc, contentDescription = null)
                        Spacer(Modifier.width(8.dp))
                        Text(stringResource(R.string.browser_nfc_read))
                    }
                    Text(stringResource(R.string.browser_nfc_read_hint), style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                    if (card != null) Text(stringResource(R.string.browser_nfc_ready),
                        style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.primary)
                }
            }
            if (externalHint) Text(stringResource(R.string.browser_authentication_external),
                style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            TextButton(onClick = { showingOptions = false }, modifier = Modifier.fillMaxWidth()) {
                Text(stringResource(R.string.action_close))
            }
        }
    }
}

@Composable
private fun BrowserAuthenticationOption(title: String, selected: Boolean, enabled: Boolean, onClick: () -> Unit,
                                        modifier: Modifier = Modifier, detail: String? = null, icon: ImageVector? = null) {
    Surface(shape = RoundedCornerShape(16.dp),
        color = if (selected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceContainerLow,
        border = BorderStroke(1.dp, if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant)) {
        Row(modifier.fillMaxWidth().selectable(selected = selected, enabled = enabled,
            role = Role.RadioButton, onClick = onClick).heightIn(min = 64.dp).padding(12.dp),
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            RadioButton(selected = selected, onClick = null, enabled = enabled)
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(title, style = MaterialTheme.typography.bodyLarge,
                    fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
                    color = if (enabled) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurfaceVariant)
                if (detail != null) Text(detail, style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            if (icon != null) Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
        }
    }
}
