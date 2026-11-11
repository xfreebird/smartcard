package md.moldsign.app.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import md.moldsign.app.R

@Composable
fun AboutContent() {
    val context = LocalContext.current
    val uriHandler = LocalUriHandler.current
    val version = remember {
        runCatching { context.packageManager.getPackageInfo(context.packageName, 0).versionName }.getOrNull().orEmpty()
    }
    Column(verticalArrangement = Arrangement.spacedBy(12.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Box(Modifier.size(72.dp).background(Color(0xFF3F6EF5))) {
            Image(painterResource(R.drawable.ic_launcher_foreground), contentDescription = null, modifier = Modifier.fillMaxSize())
        }
        Text(stringResource(R.string.app_name), style = MaterialTheme.typography.titleLarge)
        Text(stringResource(R.string.about_version, version))
        Text(stringResource(R.string.about_body), textAlign = TextAlign.Center)
        Text(stringResource(R.string.about_legal_title), style = MaterialTheme.typography.titleMedium)
        Text(stringResource(R.string.about_disclaimer_body), style = MaterialTheme.typography.bodyMedium)
        val language = androidx.compose.ui.platform.LocalConfiguration.current.locales.get(0).language
        val legalBase = "https://esemnbun.md" + if (language in listOf("ro", "ru")) "/$language" else ""
        listOf(
            R.string.about_terms to "$legalBase/terms/",
            R.string.about_privacy to "$legalBase/privacy/",
            R.string.about_disclaimer to "$legalBase/terms/",
        ).forEach { (label, url) ->
            TextButton(onClick = { uriHandler.openUri(url) }, modifier = Modifier.fillMaxWidth()) { Text(stringResource(label)) }
        }
        md.moldsign.app.ui.components.GovernmentSources()
        Text("Nicolae Ghimbovschi")
        TextButton(onClick = { uriHandler.openUri("https://esemnbun.md") }) { Text("esemnbun.md") }
    }
}
