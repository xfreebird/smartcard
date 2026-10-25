package md.moldsign.app.ui.components

import android.text.format.Formatter
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import md.moldsign.app.PickedDocument
import md.moldsign.app.R
import md.moldsign.app.ui.theme.Tokens

/** Signature formats offered per file (docs/10 "Opțiuni avansate"); PAdES only for PDFs. */
fun formatOptions(doc: PickedDocument): List<String> =
    (if (doc.isPdf) listOf("PAdES-T") else emptyList()) + listOf("XAdES-BES", "XAdES-T", "XAdES-C")

/** FormatChip (docs/10 §3): small capsule; tapping opens the per-file format menu. */
@Composable
fun FormatChip(format: String, options: List<String>, onSelect: (String) -> Unit) {
    var open by remember { mutableStateOf(false) }
    Box {
        AssistChip(
            onClick = { open = true },
            label = { Text(format, style = MaterialTheme.typography.labelMedium) },
            colors = AssistChipDefaults.assistChipColors(
                containerColor = MaterialTheme.colorScheme.secondaryContainer,
                labelColor = MaterialTheme.colorScheme.onSecondaryContainer,
            ),
            border = null,
        )
        DropdownMenu(expanded = open, onDismissRequest = { open = false }) {
            options.forEach { option ->
                DropdownMenuItem(text = { Text(option) }, onClick = { open = false; onSelect(option) })
            }
        }
    }
}

/** FileRow (docs/10 §3): doc icon, middle-truncated name, size, format chip, remove. */
@Composable
fun FileRow(doc: PickedDocument, format: String?, onFormat: ((String) -> Unit)?, onRemove: () -> Unit) {
    val context = LocalContext.current
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
        shape = RoundedCornerShape(Tokens.RadiusCard),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Row(Modifier.padding(start = Tokens.S4, top = Tokens.S2, bottom = Tokens.S2), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Outlined.Description, contentDescription = null, modifier = Modifier.size(28.dp), tint = MaterialTheme.colorScheme.primary)
            Spacer(Modifier.width(Tokens.S3))
            Column(Modifier.weight(1f)) {
                Text(doc.name, style = MaterialTheme.typography.bodyLarge, maxLines = 1, overflow = TextOverflow.MiddleEllipsis)
                if (doc.size >= 0) {
                    Text(Formatter.formatShortFileSize(context, doc.size), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            if (format != null && onFormat != null) FormatChip(format, formatOptions(doc), onFormat)
            IconButton(onClick = onRemove) {
                Icon(Icons.Outlined.Close, contentDescription = stringResource(R.string.action_remove))
            }
        }
    }
}
