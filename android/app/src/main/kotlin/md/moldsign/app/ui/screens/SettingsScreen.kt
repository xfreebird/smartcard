package md.moldsign.app.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import md.moldsign.app.R
import md.moldsign.app.presentation.MainViewModel
import md.moldsign.app.ui.components.*
import md.moldsign.app.ui.features.AppearanceSettings
import md.moldsign.app.ui.features.BrowserSigningSettings
import md.moldsign.app.ui.features.ExperimentalTokenSettings
import md.moldsign.app.ui.features.DocumentSettings

/** Preferences stay together; focused card, PIN and help tasks return to the same place. */
@Composable
fun SettingsScreen(vm: MainViewModel, enabled: Boolean, page: String, onPageChange: (String) -> Unit, onDemoChange: (Boolean) -> Unit) {
    Column(Modifier.fillMaxSize().testTag("settings.screen"), horizontalAlignment = Alignment.CenterHorizontally) {
        Column(Modifier.widthIn(max = 640.dp).fillMaxWidth().verticalScroll(rememberScrollState()).padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp)) {
            SettingsGroup {
                ListItem(colors = ListItemDefaults.colors(containerColor = androidx.compose.ui.graphics.Color.Transparent),
                    headlineContent = { Text(stringResource(R.string.demo_mode_title)) },
                    supportingContent = { Text(stringResource(R.string.demo_mode_description)) },
                    trailingContent = { Switch(checked = vm.demoMode, enabled = enabled, onCheckedChange = onDemoChange) })
            }
            SettingsSection(stringResource(R.string.settings_signing)) {
                ChoiceRow(Icons.Outlined.Badge, stringResource(R.string.settings_card_reader),
                    onClick = { onPageChange("card") }, modifier = Modifier.testTag("settings.card"))
                SettingsDivider()
                ChoiceRow(Icons.Outlined.Key, stringResource(R.string.pin_saved_title),
                    onClick = { onPageChange("pins") }, modifier = Modifier.testTag("card.savedPins"))
                SettingsDivider()
                ExperimentalTokenSettings(vm, enabled && !vm.demoMode)
            }
            SettingsSection(stringResource(R.string.settings_appearance_language)) { AppearanceSettings(enabled) }
            SettingsSection(stringResource(R.string.nav_activity)) { DocumentSettings(enabled) }
            SettingsSection(stringResource(R.string.nav_browser)) { BrowserSigningSettings(vm, enabled) }
            SettingsGroup {
                ChoiceRow(Icons.Outlined.HelpOutline, stringResource(R.string.nfc_how_it_works),
                    onClick = { onPageChange("help") }, modifier = Modifier.testTag("settings.help"))
                SettingsDivider()
                ChoiceRow(Icons.Outlined.Info, stringResource(R.string.about_title),
                    onClick = { onPageChange("about") }, modifier = Modifier.testTag("settings.about"))
            }
        }
    }
    if (page != "settings") {
        val title = stringResource(when (page) {
            "card" -> R.string.settings_card_reader
            "pins" -> R.string.pin_saved_title
            "help" -> R.string.nfc_how_it_works
            else -> R.string.about_title
        })
        FocusedTaskSheet(title, scrollable = page != "card", onDismiss = { onPageChange("settings") }) {
            when (page) {
                "card" -> CardScreen(vm, PaddingValues(0.dp))
                "pins" -> SavedCardPins(vm)
                "help" -> {
                    val method by vm.signingMethod.collectAsState()
                    if (method == MainViewModel.SigningMethod.NFC) NfcHelpContent() else ConnectionGuide()
                }
                else -> AboutContent()
            }
        }
    }
}

@Composable
private fun SettingsSection(title: String, content: @Composable ColumnScope.() -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text(title, style = MaterialTheme.typography.titleSmall, modifier = Modifier.padding(horizontal = 16.dp))
        SettingsGroup(content)
    }
}

@Composable
private fun SettingsDivider() = HorizontalDivider(Modifier.padding(start = 56.dp),
    color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.3f))

@Composable
private fun SettingsGroup(content: @Composable ColumnScope.() -> Unit) {
    Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surfaceContainerLowest) {
        Column(Modifier.fillMaxWidth(), content = content)
    }
}

/** A centred task on a tablet, a dismissible sheet on a phone; neither replaces Settings. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun FocusedTaskSheet(title: String, scrollable: Boolean = true, onDismiss: () -> Unit, content: @Composable () -> Unit) {
    val configuration = LocalConfiguration.current
    val body: @Composable () -> Unit = {
        Column(Modifier.fillMaxWidth().heightIn(max = (configuration.screenHeightDp * .85f).dp).testTag("settings.task")) {
            Row(Modifier.fillMaxWidth().padding(start = 24.dp, end = 12.dp, top = 8.dp, bottom = 8.dp),
                verticalAlignment = Alignment.CenterVertically) {
                Text(title, style = MaterialTheme.typography.headlineSmall, modifier = Modifier.weight(1f))
                IconButton(onClick = onDismiss, modifier = Modifier.testTag("settings.close")) {
                    Icon(Icons.Outlined.Close, stringResource(R.string.action_close))
                }
            }
            if (scrollable) Column(Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState())
                .navigationBarsPadding().padding(24.dp), verticalArrangement = Arrangement.spacedBy(24.dp)) { content() }
            else Box(Modifier.weight(1f, fill = false).navigationBarsPadding()) { content() }
        }
    }
    if (configuration.screenWidthDp >= 600) {
        Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
            Surface(Modifier.widthIn(max = 608.dp).fillMaxWidth().padding(24.dp), shape = RoundedCornerShape(28.dp),
                color = MaterialTheme.colorScheme.surface) { body() }
        }
    } else {
        ModalBottomSheet(onDismissRequest = onDismiss, sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)) { body() }
    }
}
