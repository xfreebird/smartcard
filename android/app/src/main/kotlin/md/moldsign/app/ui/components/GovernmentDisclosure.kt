package md.moldsign.app.ui.components

import android.content.Context
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import md.moldsign.app.R

/** Visible on first install/upgrade, and permanently accessible from Browser and About. */
@Composable
fun GovernmentDisclosure() {
    val context = LocalContext.current
    val preferences = remember { context.getSharedPreferences("public_information", Context.MODE_PRIVATE) }
    var visible by remember { mutableStateOf(!preferences.getBoolean("independence_notice_v1", false)) }
    if (visible) GovernmentDisclosureDialog {
        preferences.edit().putBoolean("independence_notice_v1", true).apply()
        visible = false
    }
}

@Composable
fun GovernmentDisclosureLink() {
    var visible by remember { mutableStateOf(false) }
    TextButton(onClick = { visible = true }, modifier = Modifier.fillMaxWidth()) {
        Text(stringResource(R.string.government_sources_action))
    }
    if (visible) GovernmentDisclosureDialog { visible = false }
}

@Composable
private fun GovernmentDisclosureDialog(onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.government_independence_title)) },
        text = { Column(Modifier.heightIn(max = 420.dp).verticalScroll(rememberScrollState())) { GovernmentSources() } },
        confirmButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.government_notice_continue)) } },
    )
}

@Composable
fun GovernmentSources() {
    val uriHandler = LocalUriHandler.current
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(stringResource(R.string.government_independence_notice), style = MaterialTheme.typography.bodyMedium)
        Text(stringResource(R.string.government_sources_explanation), style = MaterialTheme.typography.bodyMedium)
        listOf(
            "MSign" to "https://msign.gov.md/",
            "MPass" to "https://mpass.gov.md/",
            "EVO" to "https://evo.gov.md/",
            "eVMS" to "https://evms.md/",
            "MPay" to "https://mpay.gov.md/",
        ).forEach { (name, url) ->
            TextButton(onClick = { uriHandler.openUri(url) }) { Text("$name · $url") }
        }
    }
}
