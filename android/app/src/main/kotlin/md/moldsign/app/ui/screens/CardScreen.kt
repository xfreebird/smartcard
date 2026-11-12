package md.moldsign.app.ui.screens

import md.moldsign.app.presentation.toCardWalletContent

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import md.moldsign.app.presentation.MainViewModel
import md.moldsign.app.R
import md.moldsign.app.ui.components.CardWallet
import md.moldsign.app.ui.components.ConnectionGuide
import md.moldsign.app.ui.theme.Tokens

@Composable
fun CardScreen(vm: MainViewModel, padding: PaddingValues) {
    val status by vm.status.collectAsStateWithLifecycle()
    val wallet = status.wallet
    ScreenColumn(padding, fullWidth = true) {
        CardWallet(wallet.toCardWalletContent(), onSelect = vm::selectCard, onReread = vm::rereadCards, onAllowUsb = vm::requestUsbPermission, large = true, selectionEnabled = !status.busy)
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
