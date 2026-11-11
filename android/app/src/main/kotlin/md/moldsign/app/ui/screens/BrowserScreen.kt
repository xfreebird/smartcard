package md.moldsign.app.ui.screens

import md.moldsign.app.hostActivity
import android.Manifest
import android.content.Intent
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.OpenInNew
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.core.net.toUri
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import md.moldsign.app.presentation.MainViewModel
import md.moldsign.app.R
import md.moldsign.app.ui.components.CardWallet
import md.moldsign.app.ui.theme.LocalStatusColors
import md.moldsign.app.ui.theme.Tokens

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
