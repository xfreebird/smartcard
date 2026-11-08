package md.moldsign.app.ui.components

import androidx.appcompat.app.AppCompatDelegate
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.core.os.LocaleListCompat
import md.moldsign.app.MainActivity
import md.moldsign.app.R
import md.moldsign.app.presentation.MainViewModel

/** Shared mobile preferences; locale and night mode apply to this application only. */
@Composable
fun AppSettings(vm: MainViewModel, enabled: Boolean) {
    val activity = LocalContext.current as? MainActivity
    val system = stringResource(R.string.settings_system)
    var language by remember { mutableStateOf(AppCompatDelegate.getApplicationLocales().get(0)?.language ?: "system") }
    var theme by remember { mutableStateOf(activity?.appTheme ?: "system") }
    val status by vm.status.collectAsStateWithLifecycle()
    Text(stringResource(R.string.settings_appearance_language), style = MaterialTheme.typography.titleSmall)
    PreferenceChoice(
        title = stringResource(R.string.settings_language),
        value = language,
        choices = listOf("system" to system, "ro" to "Română", "en" to "English", "ru" to "Русский"),
        enabled = enabled,
    ) { value ->
        language = value
        AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags(if (value == "system") "" else value))
    }
    PreferenceChoice(
        title = stringResource(R.string.settings_theme),
        value = theme,
        choices = listOf("system" to system, "light" to stringResource(R.string.settings_light), "dark" to stringResource(R.string.settings_dark)),
        enabled = enabled,
    ) { theme = it; activity?.changeAppTheme(it) }
    var browserStamps by remember { mutableStateOf(vm.browserStampsEnabled) }
    ListItem(
        headlineContent = { Text(stringResource(R.string.stamp_browser)) },
        supportingContent = { Text(stringResource(R.string.stamp_batch_hint)) },
        trailingContent = {
            Switch(checked = browserStamps, enabled = enabled, onCheckedChange = {
                browserStamps = it
                vm.browserStampsEnabled = it
            })
        },
    )
    TextButton(onClick = vm::deleteStoredPin, enabled = enabled && !vm.demoMode && status.wallet.selectedCard?.certificate != null) {
        Text(stringResource(R.string.pin_stored_delete))
    }
}

@Composable
private fun PreferenceChoice(title: String, value: String, choices: List<Pair<String, String>>, enabled: Boolean, onSelect: (String) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    Box {
        ListItem(
            modifier = Modifier.fillMaxWidth().clickable(enabled = enabled) { expanded = true },
            headlineContent = { Text(title) },
            supportingContent = { Text(choices.firstOrNull { it.first == value }?.second ?: choices.first().second) },
        )
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            choices.forEach { (key, label) ->
                DropdownMenuItem(text = { Text(label) }, onClick = {
                    expanded = false
                    if (key != value) onSelect(key)
                })
            }
        }
    }
}
