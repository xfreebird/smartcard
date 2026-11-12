package md.moldsign.app.ui.features

import md.moldsign.app.ui.components.*

import md.moldsign.app.hostActivity

import android.text.format.Formatter
import androidx.compose.foundation.relocation.BringIntoViewRequester
import androidx.compose.foundation.relocation.bringIntoViewRequester
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.heightIn
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.material.icons.outlined.ExpandLess
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material.icons.outlined.FileCopy
import androidx.compose.foundation.border
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.*
import androidx.compose.runtime.key
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Draw
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.InsertDriveFile
import androidx.compose.material.icons.outlined.MoreVert
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
import androidx.compose.material3.TextButton
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
import md.moldsign.app.presentation.errorText
import md.moldsign.app.ui.theme.Tokens
import md.moldsign.core.SignFormat

/**
 * FormatChip (docs/10 §3): small capsule; tapping opens the per-file format menu. A PDF offers PAdES-T (default) and
 * XAdES-BES / T / C (a detached `.xml` over the PDF bytes); other files offer XAdES only. Each option shows the file it
 * will produce (`<name>-semnat.pdf|xml`).
 */
@Composable
fun FormatChip(doc: PickedDocument, format: SignFormat, onSelect: (SignFormat) -> Unit) {
    val captureIntent = LocalContext.current.hostActivity()?.intent
    val captureMenu = md.moldsign.app.DemoMode.screenshotCapture(captureIntent) && captureIntent?.getStringExtra("capture_dialog") == "format-menu"
    var open by remember(captureMenu) { mutableStateOf(false) }
    val capturePosition = remember { BringIntoViewRequester() }
    LaunchedEffect(captureMenu) {
        if (captureMenu) {
            androidx.compose.runtime.withFrameNanos { }
            capturePosition.bringIntoView()
            open = true
            android.util.Log.i("MoldSignDemo", "capture-menu-ready:sign")
        }
    }
    val description = stringResource(R.string.format_chip_description, format.displayLabel())
    Box {
        AssistChip(
            onClick = { open = true },
            label = { Text(format.displayLabel(), style = MaterialTheme.typography.labelMedium) },
            trailingIcon = { Icon(Icons.Rounded.ArrowDropDown, contentDescription = null, modifier = Modifier.size(18.dp)) },
            colors = AssistChipDefaults.assistChipColors(
                containerColor = MaterialTheme.colorScheme.secondaryContainer,
                labelColor = MaterialTheme.colorScheme.onSecondaryContainer,
                trailingIconContentColor = MaterialTheme.colorScheme.onSecondaryContainer,
            ),
            border = null,
            modifier = Modifier.bringIntoViewRequester(capturePosition).semantics { contentDescription = description },
        )
        DropdownMenu(expanded = open, onDismissRequest = { open = false }) {
            SignFormat.options(doc.isPdf).forEach { option ->
                val output = SignFormat.outputName(doc.name, option)
                DropdownMenuItem(
                    text = {
                        Column {
                            Text(option.displayLabel())
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

/** FileRows (docs/10 §3) as M3 list items: doc icon, name, size, format chip, remove. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DocumentList(
    items: List<SignItem>,
    onFormat: (SignItem, SignFormat) -> Unit,
    onRemove: (SignItem) -> Unit,
    onRetry: (SignItem) -> Unit,
    retryEnabled: Boolean,
    onStamp: (SignItem) -> Unit = {},
    onBatchStamp: (SignItem) -> Unit = {},
    onRemoveGroup: () -> Unit,
) {
    val grouped = LocalConfiguration.current.screenWidthDp < 600 && items.size > 1
    var stackExpanded by rememberSaveable { mutableStateOf(false) }
    val captureIntent = LocalContext.current.hostActivity()?.intent
    val captureMenu = md.moldsign.app.DemoMode.screenshotCapture(captureIntent) && captureIntent?.getStringExtra("capture_dialog") == "batch-menu"
    var groupMenu by remember(captureMenu) { mutableStateOf(false) }
    val captureGroupPosition = remember { BringIntoViewRequester() }
    LaunchedEffect(captureMenu, grouped) {
        if (captureMenu && grouped) {
            androidx.compose.runtime.withFrameNanos { }
            captureGroupPosition.bringIntoView()
            groupMenu = true
            android.util.Log.i("MoldSignDemo", "capture-menu-ready:sign")
        }
    }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
    if (grouped) {
        val groupDismiss = rememberSwipeToDismissBoxState(confirmValueChange = { value ->
            if (value == SwipeToDismissBoxValue.EndToStart && retryEnabled) {
                groupMenu = false
                stackExpanded = false
                onRemoveGroup()
            }
            false
        })
        SwipeToDismissBox(state = groupDismiss, enableDismissFromStartToEnd = false, enableDismissFromEndToStart = retryEnabled,
            backgroundContent = {
                Box(Modifier.fillMaxSize().clip(RoundedCornerShape(12.dp)).background(MaterialTheme.colorScheme.errorContainer).padding(20.dp), contentAlignment = Alignment.CenterEnd) {
                    Icon(Icons.Outlined.Delete, stringResource(R.string.batch_remove), tint = MaterialTheme.colorScheme.onErrorContainer)
                }
            }) {
        Box(Modifier.fillMaxWidth().padding(bottom = 6.dp)) {
            Box(Modifier.matchParentSize().padding(horizontal = 6.dp).offset(y = 6.dp)
                .background(MaterialTheme.colorScheme.surfaceContainerHighest, RoundedCornerShape(12.dp)))
            OutlinedCard(Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp)) {
                Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Row(Modifier.weight(1f).heightIn(min = 48.dp).clickable { stackExpanded = !stackExpanded }, verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Outlined.FileCopy, null, Modifier.padding(end = 12.dp))
                        Column(Modifier.weight(1f)) {
                            Text("${items.size} ${stringResource(R.string.batch_files)}", style = MaterialTheme.typography.titleMedium)
                            Text(if (items.map { it.format }.distinct().size == 1) items.first().format.displayLabel() else stringResource(R.string.batch_mixed), style = MaterialTheme.typography.labelSmall)
                            Text(stringResource(if (stackExpanded) R.string.batch_collapse else R.string.batch_expand), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary)
                        }
                        Icon(if (stackExpanded) Icons.Outlined.ExpandLess else Icons.Outlined.ExpandMore, null)
                    }
                    Box {
                        IconButton(onClick = { groupMenu = true }, enabled = retryEnabled, modifier = Modifier.bringIntoViewRequester(captureGroupPosition)) { Icon(Icons.Outlined.MoreVert, stringResource(R.string.batch_options)) }
                        DropdownMenu(expanded = groupMenu, onDismissRequest = { groupMenu = false }) {
                            DropdownMenuItem(text = { Text(stringResource(R.string.batch_options)) }, onClick = {}, enabled = false)
                            DropdownMenuItem(text = { Text(stringResource(R.string.batch_automatic)) }, onClick = {
                                groupMenu = false
                                items.forEach { onFormat(it, if (it.doc.isPdf) SignFormat.PadesT else SignFormat.XadesT) }
                            })
                            SignFormat.options(items.all { it.doc.isPdf }).forEach { format ->
                                DropdownMenuItem(text = { Text(format.displayLabel()) }, onClick = { groupMenu = false; items.forEach { onFormat(it, format) } })
                            }
                            items.firstOrNull { it.format == SignFormat.PadesT }?.let { source ->
                                HorizontalDivider()
                                DropdownMenuItem(text = { Text(stringResource(R.string.batch_stamp)) }, onClick = { groupMenu = false; onBatchStamp(source) })
                            }
                            HorizontalDivider()
                            DropdownMenuItem(text = { Text(stringResource(R.string.batch_remove), color = MaterialTheme.colorScheme.error) },
                                leadingIcon = { Icon(Icons.Outlined.Delete, null, tint = MaterialTheme.colorScheme.error) },
                                onClick = { groupMenu = false; stackExpanded = false; onRemoveGroup() })
                        }
                    }
                }
            }
        }
        }
    }
    if (!grouped || stackExpanded || items.any { it.error != null }) Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
        shape = RoundedCornerShape(Tokens.RadiusCard),
        modifier = Modifier.fillMaxWidth(),
    ) {
        items.forEachIndexed { i, item ->

            val stampSummary = if (item.format != SignFormat.PadesT) null else item.stamp?.let {
                if (it.allPages) stringResource(R.string.file_stamp_all) else "${stringResource(R.string.file_stamp_page)} ${it.page+1}"
            } ?: if (item.format == SignFormat.PadesT) stringResource(R.string.file_stamp_off) else null
            key(item.doc.uri) {
                val dismiss = rememberSwipeToDismissBoxState(confirmValueChange = { value ->
                    if (value == SwipeToDismissBoxValue.EndToStart && retryEnabled) onRemove(item)
                    false
                })
                SwipeToDismissBox(state=dismiss, enableDismissFromStartToEnd=false, enableDismissFromEndToStart=retryEnabled,
                    backgroundContent={
                        Box(Modifier.fillMaxSize().background(if (dismiss.dismissDirection != SwipeToDismissBoxValue.Settled) MaterialTheme.colorScheme.errorContainer else androidx.compose.ui.graphics.Color.Transparent).padding(20.dp), contentAlignment=Alignment.CenterEnd) {
                            if (dismiss.dismissDirection != SwipeToDismissBoxValue.Settled) Icon(Icons.Outlined.Delete,stringResource(R.string.file_remove),tint=MaterialTheme.colorScheme.onErrorContainer)
                        }
                    }) {
            DocumentRow(item.doc, item.format, { onFormat(item, it) }, { onRemove(item) },
                summary = listOfNotNull(item.format.displayLabel(), stampSummary).joinToString(" · "),
                onStamp = if (item.format == SignFormat.PadesT) ({ onStamp(item) }) else null,
                hasStamp = item.stamp != null, optionsEnabled = retryEnabled, stampSummary = stampSummary)
                }
            }
            item.error?.let { error ->
                val captureErrorPosition = remember { BringIntoViewRequester() }
                val captureIntent = LocalContext.current.hostActivity()?.intent
                LaunchedEffect(error) {
                    if (md.moldsign.app.DemoMode.screenshotCapture(captureIntent) && captureIntent?.getStringExtra("demo") == "sign-failure") {
                        androidx.compose.runtime.withFrameNanos { }
            captureErrorPosition.bringIntoView()
                        android.util.Log.i("MoldSignDemo", "capture-scroll-ready:sign")
                    }
                }
                Column(Modifier.fillMaxWidth().bringIntoViewRequester(captureErrorPosition).padding(start = 16.dp, end = 16.dp, bottom = 12.dp)) {
                    Text(errorText(error), color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodyMedium)
                }
            }
        }
    }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun DocumentRow(doc: PickedDocument, format: SignFormat?, onFormat: ((SignFormat) -> Unit)?, onRemove: () -> Unit, summary: String? = null, onStamp: (() -> Unit)? = null, hasStamp: Boolean = false, optionsEnabled: Boolean = true, stampSummary: String? = null) {
    var optionsOpen by remember { mutableStateOf(false) }
    val context = LocalContext.current
    val fileActions: @Composable () -> Unit = {

            if (format != null && onFormat != null) Box {
                IconButton(onClick={ optionsOpen=true }, enabled=optionsEnabled) {
                    Icon(Icons.Outlined.MoreVert, stringResource(R.string.file_options))
                }
                DropdownMenu(expanded=optionsOpen, onDismissRequest={ optionsOpen=false }) {
                    DropdownMenuItem(text={ Text(stringResource(R.string.file_signing_type)) }, onClick={}, enabled=false)
                    SignFormat.options(doc.isPdf).forEach { option ->
                        DropdownMenuItem(text={ Text(option.displayLabel()) }, leadingIcon={
                            if(option==format) Icon(Icons.Rounded.Check,null) else Spacer(Modifier.size(24.dp))
                        }, onClick={ optionsOpen=false; onFormat(option) })
                    }
                    if (onStamp != null) {
                        HorizontalDivider()
                        DropdownMenuItem(text={ Text(stringResource(if(hasStamp) R.string.stamp_edit else R.string.stamp_add)) }, onClick={ optionsOpen=false; onStamp() })
                    }
                    HorizontalDivider()
                    DropdownMenuItem(text={ Text(stringResource(R.string.file_remove)) }, onClick={ optionsOpen=false; onRemove() })
                }
            } else IconButton(onClick=onRemove) {
                Icon(Icons.Outlined.Close, contentDescription=stringResource(R.string.action_remove))
            }

    }
    if (format != null && LocalConfiguration.current.screenWidthDp < 600) {
        Surface(modifier = Modifier.fillMaxWidth().padding(4.dp), shape = RoundedCornerShape(12.dp),
            border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant),
            color = MaterialTheme.colorScheme.surfaceContainerLow) {
            Column(Modifier.padding(start = 12.dp, end = 8.dp, top = 4.dp, bottom = 10.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Icon(if (doc.isPdf) Icons.Outlined.PictureAsPdf else Icons.Outlined.Description,
                        null, Modifier.size(20.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text(doc.name, modifier = Modifier.weight(1f), style = MaterialTheme.typography.bodyMedium,
                        maxLines = 1, overflow = androidx.compose.ui.text.style.TextOverflow.MiddleEllipsis)
                    if (doc.size >= 0) Text(Formatter.formatShortFileSize(context, doc.size),
                        style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    fileActions()
                }
                FlowRow(Modifier.padding(start = 28.dp, end = 4.dp), horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    SelectionTag(format.displayLabel(), if (format == SignFormat.PadesT) Icons.Outlined.PictureAsPdf else Icons.Outlined.Description)
                    stampSummary?.let { SelectionTag(it, Icons.Outlined.Draw, stamp = true, active = hasStamp) }
                }
            }
        }
    } else {
    ListItem(
        modifier=Modifier.padding(4.dp).border(1.dp,MaterialTheme.colorScheme.outlineVariant,RoundedCornerShape(12.dp)).clip(RoundedCornerShape(12.dp)),
        leadingContent = {
            Icon(
                if (doc.isPdf) Icons.Outlined.PictureAsPdf else if (doc.mime?.contains("xml") == true) Icons.Outlined.Description else Icons.AutoMirrored.Outlined.InsertDriveFile,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
            )
        },
        headlineContent = { Text(doc.name) },
        supportingContent = {
            Column {
                if (doc.size >= 0) Text(Formatter.formatShortFileSize(context, doc.size))
                if (format != null) FlowRow(horizontalArrangement=Arrangement.spacedBy(6.dp), verticalArrangement=Arrangement.spacedBy(4.dp)) {
                    SelectionTag(format.displayLabel(), if(format==SignFormat.PadesT) Icons.Outlined.PictureAsPdf else Icons.Outlined.Description)
                    stampSummary?.let { SelectionTag(it,Icons.Outlined.Draw,stamp=true,active=hasStamp) }
                } else summary?.let { Text(it,style=MaterialTheme.typography.bodySmall) }
            }
        },
        trailingContent = fileActions,
        colors = ListItemDefaults.colors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
    )
    }
}

@Composable
private fun SignFormat.displayLabel(): String = stringResource(when(this) {
    SignFormat.PadesT -> R.string.format_pdf
    SignFormat.XadesBes -> R.string.format_xml
    SignFormat.XadesT -> R.string.format_xml_time
    SignFormat.XadesC -> R.string.format_xml_data
})

@Composable
private fun SelectionTag(text: String, icon: ImageVector, stamp: Boolean = false, active: Boolean = true) {
    val background = if (!stamp) MaterialTheme.colorScheme.primaryContainer else if (active) MaterialTheme.colorScheme.tertiaryContainer else MaterialTheme.colorScheme.surfaceContainerHigh
    val foreground = if (!stamp) MaterialTheme.colorScheme.onPrimaryContainer else if (active) MaterialTheme.colorScheme.onTertiaryContainer else MaterialTheme.colorScheme.onSurfaceVariant
    Surface(shape=RoundedCornerShape(6.dp),color=background,contentColor=foreground) {
        Row(Modifier.padding(horizontal=5.dp,vertical=2.dp),verticalAlignment=Alignment.CenterVertically,horizontalArrangement=Arrangement.spacedBy(4.dp)) {
            Icon(icon,null,Modifier.size(12.dp))
            Text(text,style=MaterialTheme.typography.labelSmall.copy(fontSize=10.sp))
        }
    }
}
