package md.moldsign.app.ui.components

import android.text.format.Formatter
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.InsertDriveFile
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.PictureAsPdf
import androidx.compose.material.icons.outlined.UploadFile
import androidx.compose.material.icons.rounded.ArrowDropDown
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedCard
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
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import md.moldsign.app.application.PickedDocument
import md.moldsign.app.R
import md.moldsign.app.application.SignItem
import md.moldsign.app.ui.theme.Tokens
import md.moldsign.core.SignFormat

/**
 * FormatChip (docs/10 §3): small capsule; tapping opens the per-file format menu. A PDF offers PAdES-T (default) and
 * XAdES-BES / T / C (a detached `.xml` over the PDF bytes); other files offer XAdES only. Each option shows the file it
 * will produce (`<name>-semnat.pdf|xml`).
 */
@Composable
fun FormatChip(doc: PickedDocument, format: SignFormat, onSelect: (SignFormat) -> Unit) {
    var open by remember { mutableStateOf(false) }
    val description = stringResource(R.string.format_chip_description, format.label)
    Box {
        AssistChip(
            onClick = { open = true },
            label = { Text(format.label, style = MaterialTheme.typography.labelMedium) },
            trailingIcon = { Icon(Icons.Rounded.ArrowDropDown, contentDescription = null, modifier = Modifier.size(18.dp)) },
            colors = AssistChipDefaults.assistChipColors(
                containerColor = MaterialTheme.colorScheme.secondaryContainer,
                labelColor = MaterialTheme.colorScheme.onSecondaryContainer,
                trailingIconContentColor = MaterialTheme.colorScheme.onSecondaryContainer,
            ),
            border = null,
            modifier = Modifier.semantics { contentDescription = description },
        )
        DropdownMenu(expanded = open, onDismissRequest = { open = false }) {
            SignFormat.options(doc.isPdf).forEach { option ->
                val output = SignFormat.outputName(doc.name, option)
                DropdownMenuItem(
                    text = {
                        Column {
                            Text(option.label)
                            Text(
                                stringResource(if (option.xadesLevel == null) R.string.format_output_pades else R.string.format_output_xades, output),
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                    },
                    leadingIcon = {
                        if (option == format) Icon(Icons.Rounded.Check, contentDescription = null) else Spacer(Modifier.size(24.dp))
                    },
                    onClick = {
                        open = false
                        onSelect(option)
                    },
                )
            }
        }
    }
}

/** "Alege documentele": the phone's drop zone (docs/10 DropZone), an outlined card that opens the picker. */
@Composable
fun DocumentPickZone(
    onPick: () -> Unit,
    modifier: Modifier = Modifier,
    title: String = stringResource(R.string.sign_choose_title),
    body: String = stringResource(R.string.sign_choose_body),
) {
    OutlinedCard(
        onClick = onPick,
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(Tokens.RadiusCard),
        colors = CardDefaults.outlinedCardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
    ) {
        Column(Modifier.fillMaxWidth().padding(Tokens.S6), horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(Icons.Outlined.UploadFile, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(32.dp))
            Spacer(Modifier.height(Tokens.S2))
            Text(title, style = MaterialTheme.typography.titleMedium)
            Text(
                body,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
            )
        }
    }
}

/** The "Alege documentele" tile shrunk to one row, under the list once documents are added. */
@Composable
fun DocumentAddTile(onPick: () -> Unit, modifier: Modifier = Modifier) {
    OutlinedCard(
        onClick = onPick,
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(Tokens.RadiusCard),
        colors = CardDefaults.outlinedCardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
    ) {
        Row(Modifier.fillMaxWidth().padding(horizontal = Tokens.S4, vertical = Tokens.S3), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Outlined.UploadFile, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(22.dp))
            Spacer(Modifier.width(Tokens.S3))
            Column {
                Text(stringResource(R.string.sign_add_more), style = MaterialTheme.typography.titleSmall)
                Text(
                    stringResource(R.string.sign_choose_body),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

/** FileRows (docs/10 §3) as M3 list items: doc icon, name, size, format chip, remove. */
@Composable
fun DocumentList(items: List<SignItem>, onFormat: (SignItem, SignFormat) -> Unit, onRemove: (SignItem) -> Unit) {
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
        shape = RoundedCornerShape(Tokens.RadiusCard),
        modifier = Modifier.fillMaxWidth(),
    ) {
        items.forEachIndexed { i, item ->
            if (i > 0) HorizontalDivider(Modifier.padding(start = 56.dp))
            DocumentRow(item.doc, item.format, { onFormat(item, it) }, { onRemove(item) })
        }
    }
}

@Composable
fun DocumentRow(doc: PickedDocument, format: SignFormat?, onFormat: ((SignFormat) -> Unit)?, onRemove: () -> Unit) {
    val context = LocalContext.current
    ListItem(
        leadingContent = {
            Icon(
                if (doc.isPdf) Icons.Outlined.PictureAsPdf else if (doc.mime?.contains("xml") == true) Icons.Outlined.Description else Icons.AutoMirrored.Outlined.InsertDriveFile,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
            )
        },
        headlineContent = { Text(doc.name) },
        supportingContent = if (doc.size >= 0) {
            { Text(Formatter.formatShortFileSize(context, doc.size)) }
        } else {
            null
        },
        trailingContent = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (format != null && onFormat != null) FormatChip(doc, format, onFormat)
                IconButton(onClick = onRemove) {
                    Icon(Icons.Outlined.Close, contentDescription = stringResource(R.string.action_remove))
                }
            }
        },
        colors = ListItemDefaults.colors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
    )
}
