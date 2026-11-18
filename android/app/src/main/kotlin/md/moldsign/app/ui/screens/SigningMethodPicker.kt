package md.moldsign.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import md.moldsign.app.R
import md.moldsign.app.presentation.MainViewModel
import md.moldsign.app.presentation.toCardWalletContent
import md.moldsign.app.ui.components.CardWallet
import md.moldsign.app.ui.components.ConnectionGuide

/** NFC stays compact; reader setup and connected cards are visible where the user needs them. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SigningMethodPicker(vm: MainViewModel, compact: Boolean = false, signing: Boolean = false, inlineReaderCards: Boolean = false) {
    val method by vm.signingMethod.collectAsStateWithLifecycle()
    val status by vm.status.collectAsStateWithLifecycle()
    val working by vm.working.collectAsStateWithLifecycle()
    val identity by vm.nfcIdentity.collectAsStateWithLifecycle()
    val cards by vm.knownCards.collectAsStateWithLifecycle()
    val enabled = !working && !status.busy
    val nfc = method == MainViewModel.SigningMethod.NFC
    val home = signing && !compact
    val phoneHome = home && androidx.compose.ui.platform.LocalConfiguration.current.screenWidthDp < 600
    val readerHero = home && !nfc
    var choosing by remember { mutableStateOf(false) }
    var methods by remember { mutableStateOf(false) }
    var readerCards by remember { mutableStateOf(false) }
    var readerHelp by remember { mutableStateOf(false) }
    var help by remember { mutableStateOf(false) }
    Column(Modifier.widthIn(max = 560.dp).fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(if (compact) 12.dp else if (phoneHome) 8.dp else 24.dp)) {
        if (!compact) {
            if (signing) Box(Modifier.fillMaxWidth().heightIn(min = if (phoneHome) 250.dp else 310.dp), contentAlignment = Alignment.Center) {
                if (readerHero) CardWallet(status.wallet.toCardWalletContent(), onSelect = vm::selectCard, onReread = vm::rereadCards,
                    onAllowUsb = vm::requestUsbPermission, selectionEnabled = enabled, modifier = Modifier.widthIn(max = if (phoneHome) 340.dp else 420.dp).testTag("reader.cards"))
                else SigningCardIllustration(nfc = nfc)
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(stringResource(if (signing) R.string.guided_start else R.string.guided_card_title),
                    style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
                if (!phoneHome) Text(stringResource(if (signing) R.string.guided_start_body else R.string.guided_card_body),
                    style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
            }
        }
        Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surfaceContainerLowest) {
            Column {
                Box {
                    ChoiceRow(if (nfc) Icons.Outlined.Nfc else Icons.Outlined.CreditCard,
                        stringResource(if (nfc) R.string.guided_contactless else R.string.guided_reader),
                        caption = stringResource(R.string.guided_method_caption), enabled = enabled,
                        modifier = Modifier.heightIn(min = if (signing && !compact) 96.dp else 0.dp).testTag("sign.method"), onClick = { methods = true })
                    DropdownMenu(expanded = methods, onDismissRequest = { methods = false }) {
                        DropdownMenuItem(text = { Text(stringResource(R.string.guided_contactless)) },
                            leadingIcon = { Icon(Icons.Outlined.Nfc, null) }, enabled = vm.nfcAvailable && enabled,
                            onClick = { vm.selectSigningMethod(MainViewModel.SigningMethod.NFC); methods = false }, modifier = Modifier.testTag("sign.nfc"))
                        DropdownMenuItem(text = { Text(stringResource(R.string.guided_reader)) },
                            leadingIcon = { Icon(Icons.Outlined.CreditCard, null) }, enabled = enabled,
                            onClick = { vm.selectSigningMethod(MainViewModel.SigningMethod.Reader); methods = false }, modifier = Modifier.testTag("sign.reader"))
                    }
                }
                if (!nfc && !inlineReaderCards && !readerHero) {
                    HorizontalDivider(Modifier.padding(start = 56.dp), color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.3f))
                    ChoiceRow(Icons.Outlined.PersonOutline,
                        status.wallet.selectedCard?.certificate?.commonName
                            ?: md.moldsign.app.presentation.statusLabel(androidx.compose.ui.platform.LocalContext.current, status),
                        caption = status.wallet.selectedCard?.readerName,
                        enabled = enabled, onClick = { readerCards = true }, modifier = Modifier.testTag("signing.reader.cards"))
                }
                if (nfc && cards.isNotEmpty() && !home) {
                    HorizontalDivider(Modifier.padding(start = 56.dp), color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.3f))
                    ChoiceRow(Icons.Outlined.PersonOutline, identity?.commonName ?: stringResource(R.string.nfc_card_any),
                        enabled = enabled, onClick = { choosing = true }, modifier = Modifier.testTag("nfc.card"))
                }
            }
        }
        if (!nfc && inlineReaderCards) {
            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
                CardWallet(status.wallet.toCardWalletContent(), onSelect = vm::selectCard, onReread = vm::rereadCards,
                    onAllowUsb = vm::requestUsbPermission, selectionEnabled = enabled, modifier = Modifier.testTag("reader.cards"))
                if (status.wallet.cards.size > 1) Text(stringResource(R.string.guided_reader_swipe),
                    style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center)
            }
        }
        TextButton(onClick = { if (nfc) help = true else readerHelp = true }, modifier = Modifier.testTag("nfc.help.open")) {
            Icon(Icons.Outlined.HelpOutline, null, Modifier.size(18.dp))
            Spacer(Modifier.width(8.dp))
            Text(stringResource(R.string.nfc_how_it_works))
        }
    }
    if (readerCards) ModalBottomSheet(onDismissRequest = { readerCards = false },
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)) {
        Column(Modifier.verticalScroll(rememberScrollState()).navigationBarsPadding().padding(24.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
            Text(stringResource(R.string.settings_card_reader), style = MaterialTheme.typography.headlineSmall)
            CardWallet(status.wallet.toCardWalletContent(), onSelect = vm::selectCard, onReread = vm::rereadCards,
                onAllowUsb = vm::requestUsbPermission, selectionEnabled = enabled, modifier = Modifier.testTag("reader.cards"))
            if (status.wallet.cards.size > 1) Text(stringResource(R.string.guided_reader_swipe))
            TextButton(onClick = { readerCards = false }, modifier = Modifier.fillMaxWidth()) { Text(stringResource(R.string.action_close)) }
        }
    }
    if (help) NfcHelpDialog { help = false }
    if (readerHelp) ModalBottomSheet(onDismissRequest = { readerHelp = false },
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)) {
        Column(Modifier.verticalScroll(rememberScrollState()).navigationBarsPadding().padding(24.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
            ConnectionGuide()
            TextButton(onClick = { readerHelp = false }, modifier = Modifier.fillMaxWidth()) { Text(stringResource(R.string.action_close)) }
        }
    }
    if (choosing) ModalBottomSheet(onDismissRequest = { choosing = false }) {
        Column(Modifier.verticalScroll(rememberScrollState()).padding(24.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(stringResource(R.string.nfc_choose_card), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            TextButton(onClick = { vm.selectNfcCard(null); choosing = false }, modifier = Modifier.fillMaxWidth().testTag("nfc.another")) {
                Text(stringResource(R.string.nfc_another_card))
            }
            cards.forEach { card ->
                TextButton(onClick = { vm.selectNfcCard(card); choosing = false }, modifier = Modifier.fillMaxWidth()) {
                    Text(card.commonName, Modifier.weight(1f))
                    Text(card.serialHex.takeLast(8), style = MaterialTheme.typography.bodySmall)
                }
            }
        }
    }
}

@Composable
fun ChoiceRow(icon: androidx.compose.ui.graphics.vector.ImageVector, title: String, modifier: Modifier = Modifier,
              caption: String? = null, enabled: Boolean = true, onClick: () -> Unit) {
    Surface(onClick = onClick, enabled = enabled, color = Color.Transparent, modifier = modifier.fillMaxWidth()) {
        Row(Modifier.padding(18.dp).heightIn(min = 28.dp), verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            Icon(icon, null, Modifier.size(24.dp), tint = MaterialTheme.colorScheme.primary)
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                if (caption != null) Text(caption, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(title, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium)
            }
            Icon(Icons.AutoMirrored.Outlined.KeyboardArrowRight, null, Modifier.size(18.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
fun SigningCardIllustration(nfc: Boolean = true) {
    val brand = MaterialTheme.colorScheme.primary
    Box(Modifier.size(230.dp, 175.dp), contentAlignment = Alignment.Center) {
        Box(Modifier.size(210.dp, 140.dp).rotate(7f).background(brand.copy(alpha = 0.07f), RoundedCornerShape(22.dp)))
        Row(Modifier.size(192.dp, 122.dp).rotate(-6f)
            .background(Brush.linearGradient(listOf(brand, brand.copy(alpha = 0.78f))), RoundedCornerShape(20.dp)),
            horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Outlined.Badge, null, Modifier.size(46.dp), tint = Color.White.copy(alpha = 0.9f))
            Spacer(Modifier.width(16.dp))
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Box(Modifier.size(48.dp, 5.dp).background(Color.White.copy(alpha = 0.9f), CircleShape))
                Box(Modifier.size(34.dp, 5.dp).background(Color.White.copy(alpha = 0.45f), CircleShape))
            }
        }
        Surface(modifier = Modifier.align(Alignment.BottomEnd).size(64.dp), shape = CircleShape,
            color = MaterialTheme.colorScheme.surfaceContainerLowest, shadowElevation = 3.dp) {
            Box(contentAlignment = Alignment.Center) { Icon(if (nfc) Icons.Outlined.Nfc else Icons.Outlined.CreditCard,
                null, Modifier.size(30.dp), tint = brand) }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NfcHelpDialog(onDismiss: () -> Unit) {
    ModalBottomSheet(onDismissRequest = onDismiss, modifier = Modifier.testTag("nfc.help")) {
        Column(Modifier.verticalScroll(rememberScrollState()).padding(24.dp), verticalArrangement = Arrangement.spacedBy(24.dp)) {
            Text(stringResource(R.string.nfc_how_it_works), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            NfcHelpContent()
            TextButton(onClick = onDismiss, modifier = Modifier.fillMaxWidth().testTag("nfc.help.close")) { Text(stringResource(R.string.action_close)) }
        }
    }
}

@Composable
fun NfcHelpContent() {
    Column(verticalArrangement = Arrangement.spacedBy(24.dp)) {
            Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) { SigningCardIllustration() }
            listOf(R.string.nfc_guide_document to R.string.nfc_guide_document_body,
                R.string.nfc_guide_pin to R.string.nfc_guide_pin_body,
                R.string.nfc_guide_tap to R.string.nfc_guide_tap_android).forEachIndexed { index, (title, detail) ->
                Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    Text((index + 1).toString(), style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(stringResource(title), style = MaterialTheme.typography.titleMedium)
                        Text(stringResource(detail), style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
            Text(stringResource(R.string.nfc_guide_result), style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
fun SavedCardPins(vm: MainViewModel) {
    if (vm.demoMode) return
    val cards by vm.knownCards.collectAsStateWithLifecycle()
    val ids by vm.savedPinIds.collectAsStateWithLifecycle()
    val working by vm.working.collectAsStateWithLifecycle()
    val status by vm.status.collectAsStateWithLifecycle()
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(stringResource(R.string.pin_shared_methods), style = MaterialTheme.typography.bodySmall)
        val accounts = (cards.map { it.sha1Hex } + ids.sorted()).distinct()
        if (accounts.isEmpty()) Text(stringResource(R.string.pin_saved_empty), style = MaterialTheme.typography.bodyMedium)
        accounts.forEach { id ->
            key(id) {
                val card = cards.firstOrNull { it.sha1Hex == id } ?: status.wallet.cards.firstNotNullOfOrNull {
                    slot -> slot.certificate?.takeIf { it.sha1Hex == id }
                }
                val name = card?.commonName ?: stringResource(R.string.nav_card)
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text(name)
                        val credential = stringResource(if (id in ids) R.string.card_pin_saved else R.string.ui_no_saved_pins)
                        Text("${card?.serialHex?.takeLast(8) ?: id.takeLast(8)}  ·  $credential",
                            style = MaterialTheme.typography.bodySmall)
                    }
                    ForgetCardButton(name, enabled = !working && !status.busy) { vm.forgetCard(id) }
                }
            }
        }
    }
}

@Composable
internal fun ForgetCardButton(name: String, enabled: Boolean, onForget: () -> Unit) {
    var confirming by remember(name) { mutableStateOf(false) }
    TextButton(onClick = { confirming = true }, enabled = enabled,
        colors = ButtonDefaults.textButtonColors(contentColor = MaterialTheme.colorScheme.error)) {
        Text(stringResource(R.string.card_forget))
    }
    if (confirming) AlertDialog(
        onDismissRequest = { confirming = false },
        title = { Text(stringResource(R.string.card_forget)) },
        text = { Text(stringResource(R.string.card_forget_message, name)) },
        confirmButton = {
            TextButton(enabled = enabled, onClick = { confirming = false; onForget() }) {
                Text(stringResource(R.string.card_forget))
            }
        },
        dismissButton = {
            TextButton(onClick = { confirming = false }) { Text(stringResource(R.string.action_cancel)) }
        }
    )
}
