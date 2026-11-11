package md.moldsign.app.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import md.moldsign.app.ui.theme.Tokens

/** A bounded reading width on large windows; destination content keeps native nonzero gutters. */
@Composable
internal fun ScreenColumn(padding: PaddingValues, fullWidth: Boolean = false, content: @Composable ColumnScope.() -> Unit) {
    Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.TopCenter) {
        Column(
            Modifier
                .then(if (fullWidth) Modifier else Modifier.widthIn(max = 680.dp))
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(vertical = Tokens.S3),
            verticalArrangement = Arrangement.spacedBy(Tokens.S4),
            horizontalAlignment = Alignment.CenterHorizontally,
            content = content,
        )
    }
}

internal val Gutter = Modifier.padding(horizontal = Tokens.S4)

@Composable
internal fun SectionHeader(title: String, modifier: Modifier = Gutter, action: (@Composable () -> Unit)? = null) {
    Row(modifier.fillMaxWidth().heightIn(min = 48.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(title, style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.weight(1f))
        action?.invoke()
    }
}

internal fun mimeOf(name: String) = when { name.endsWith(".xml", ignoreCase = true) -> "application/xml"; name.endsWith(".pdf", ignoreCase = true) -> "application/pdf"; else -> "application/octet-stream" }
