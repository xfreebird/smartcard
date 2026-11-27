package md.moldsign.app.ui.features

import md.moldsign.app.ui.components.*

import md.moldsign.app.hostActivity

import androidx.appcompat.app.AppCompatDelegate
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.ui.graphics.Color
import androidx.compose.foundation.layout.padding
import androidx.compose.ui.unit.dp
import androidx.compose.material3.ListItem
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import md.moldsign.app.MainActivity
import md.moldsign.app.R
import md.moldsign.app.presentation.MainViewModel

/** Shared mobile preferences; locale and night mode apply to this application only. */
@Composable
fun AppearanceSettings(enabled: Boolean) {
    val activity = LocalContext.current.hostActivity() as? MainActivity
    val system = stringResource(R.string.settings_system)
    var language by remember { mutableStateOf(AppCompatDelegate.getApplicationLocales().get(0)?.language ?: "system") }
    val theme = activity?.themePreference ?: "system"
    PreferenceChoice(
        title = stringResource(R.string.settings_language),
        value = language,
        choices = listOf("system" to system, "ro" to "Română", "en" to "English", "ru" to "Русский"),
        enabled = enabled,
    ) { value ->
        language = value
        activity?.changeAppLanguage(value)
    }
    PreferenceChoice(
        title = stringResource(R.string.settings_theme),
        value = theme,
        choices = listOf("system" to system, "light" to stringResource(R.string.settings_light), "dark" to stringResource(R.string.settings_dark)),
        enabled = enabled,
    ) { activity?.changeAppTheme(it) }
}

@Composable
fun DocumentSettings(enabled: Boolean) {
    val context = LocalContext.current
    var widgetRecents by remember { mutableStateOf(md.moldsign.app.widget.DocumentsWidget.showsRecents(context)) }
    ListItem(
        colors = ListItemDefaults.colors(containerColor = Color.Transparent),
        headlineContent = { Text(stringResource(R.string.widget_show_recents)) },
        supportingContent = { Text(stringResource(R.string.widget_recents_hint)) },
        trailingContent = { Switch(checked = widgetRecents, enabled = enabled, onCheckedChange = {
            widgetRecents = it
            context.getSharedPreferences("settings", android.content.Context.MODE_PRIVATE).edit()
                .putBoolean(md.moldsign.app.widget.DocumentsWidget.SHOW_RECENTS, it).apply()
            md.moldsign.app.widget.DocumentsWidget.refresh(context)
        }) },
    )
}

@Composable
fun BrowserSigningSettings(vm: MainViewModel, enabled: Boolean) {
    var browserStamps by remember { mutableStateOf(vm.browserStampsEnabled) }
    ListItem(
        colors = ListItemDefaults.colors(containerColor = Color.Transparent),
        headlineContent = { Text(stringResource(R.string.stamp_browser)) },
        supportingContent = { Text(stringResource(R.string.stamp_batch_hint)) },
        trailingContent = {
            Switch(checked = browserStamps, enabled = enabled, onCheckedChange = {
                browserStamps = it
                vm.browserStampsEnabled = it
            })
        },
    )

}

/** Phase TOK: USB signing tokens, experimental and off by default (recognition only until the drivers land). */
@Composable
fun ExperimentalTokenSettings(vm: MainViewModel, enabled: Boolean) {
    var tokens by remember { mutableStateOf(vm.experimentalTokensEnabled) }
    ListItem(
        colors = ListItemDefaults.colors(containerColor = Color.Transparent),
        modifier = Modifier.testTag("settings.experimentalTokens"),
        headlineContent = { Text(stringResource(R.string.token_experimental_title)) },
        supportingContent = { Text(stringResource(R.string.token_experimental_detail)) },
        trailingContent = {
            Switch(checked = tokens, enabled = enabled, onCheckedChange = {
                tokens = it
                vm.experimentalTokensEnabled = it
            })
        },
    )
}

@Composable
private fun PreferenceChoice(title: String, value: String, choices: List<Pair<String, String>>, enabled: Boolean, onSelect: (String) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    Box {
        ListItem(
        colors = ListItemDefaults.colors(containerColor = Color.Transparent),
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
