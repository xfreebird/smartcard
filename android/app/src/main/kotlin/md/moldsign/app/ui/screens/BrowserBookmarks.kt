package md.moldsign.app.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AccountBalance
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.PersonOutline
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.unit.dp
import md.moldsign.app.R
import md.moldsign.app.application.BookmarkIcon
import md.moldsign.app.application.BookmarkUrl
import md.moldsign.app.application.BrowserBookmark

@Composable
internal fun BookmarkImage(bookmark: BrowserBookmark, modifier: Modifier = Modifier.size(24.dp)) {
    if (bookmark.builtinImage != null) Image(painterResource(bookmark.builtinImage), contentDescription = null, modifier = modifier)
    else Icon(bookmark.icon.vector(), contentDescription = null, modifier = modifier)
}

private fun BookmarkIcon.vector(): ImageVector = when (this) {
    BookmarkIcon.Globe -> Icons.Outlined.Language
    BookmarkIcon.Bookmark -> Icons.Outlined.BookmarkBorder
    BookmarkIcon.Document -> Icons.Outlined.Description
    BookmarkIcon.Person -> Icons.Outlined.PersonOutline
    BookmarkIcon.Building -> Icons.Outlined.AccountBalance
    BookmarkIcon.Star -> Icons.Outlined.StarBorder
}

@Composable
private fun BookmarkIcon.label(): String = stringResource(when (this) {
    BookmarkIcon.Globe -> R.string.browser_bookmark_icon_globe
    BookmarkIcon.Bookmark -> R.string.browser_bookmark_icon_bookmark
    BookmarkIcon.Document -> R.string.browser_bookmark_icon_document
    BookmarkIcon.Person -> R.string.browser_bookmark_icon_person
    BookmarkIcon.Building -> R.string.browser_bookmark_icon_building
    BookmarkIcon.Star -> R.string.browser_bookmark_icon_star
})

@Composable
internal fun ManageBookmarksDialog(
    bookmarks: List<BrowserBookmark>,
    onDismiss: () -> Unit,
    onEdit: (BrowserBookmark?) -> Unit,
    onRemove: (BrowserBookmark) -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.browser_bookmark_manage)) },
        text = {
            Column(Modifier.fillMaxWidth().heightIn(max = 400.dp).verticalScroll(rememberScrollState())) {
                if (bookmarks.isEmpty()) Text(stringResource(R.string.browser_bookmark_empty))
                bookmarks.forEach { bookmark ->
                    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                        Row(Modifier.weight(1f).clickable { onEdit(bookmark) }.padding(vertical = 12.dp),
                            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            BookmarkImage(bookmark)
                            Column(Modifier.weight(1f)) {
                                Text(bookmark.title, style = MaterialTheme.typography.bodyLarge)
                                Text(bookmark.url, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                        IconButton(onClick = { onRemove(bookmark) }) {
                            Icon(Icons.Outlined.Delete, contentDescription = "${stringResource(R.string.action_remove)} ${bookmark.title}")
                        }
                    }
                }
            }
        },
        confirmButton = { TextButton(onClick = { onEdit(null) }) {
            Icon(Icons.Outlined.Add, contentDescription = null)
            Spacer(Modifier.width(8.dp))
            Text(stringResource(R.string.browser_bookmark_add))
        } },
        dismissButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.browser_close)) } },
    )
}

@Composable
internal fun EditBookmarkDialog(
    existing: BrowserBookmark?,
    initialUrl: String,
    onDismiss: () -> Unit,
    onSave: (String, String, BookmarkIcon, Boolean) -> Unit,
) {
    var title by remember(existing?.id) { mutableStateOf(existing?.title.orEmpty()) }
    var url by remember(existing?.id) { mutableStateOf(existing?.url ?: initialUrl) }
    var icon by remember(existing?.id) { mutableStateOf(existing?.icon ?: BookmarkIcon.Globe) }
    var keepWebsiteImage by remember(existing?.id) { mutableStateOf(existing?.builtinImage != null) }
    val valid = title.isNotBlank() && BookmarkUrl.normalize(url) != null
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(if (existing == null) R.string.browser_bookmark_add else R.string.browser_bookmark_edit)) },
        text = {
            Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(value = title, onValueChange = { title = it }, label = { Text(stringResource(R.string.browser_bookmark_title)) },
                    singleLine = true, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = url, onValueChange = { url = it }, label = { Text(stringResource(R.string.browser_address)) },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri), modifier = Modifier.fillMaxWidth())
                Text(stringResource(R.string.browser_bookmark_icon), style = MaterialTheme.typography.titleSmall)
                if (keepWebsiteImage && existing != null) BookmarkImage(existing, Modifier.size(32.dp))
                // Two rows stay within narrow phone dialogs and provide accessible native selection controls.
                BookmarkIcon.entries.chunked(3).forEach { row ->
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        row.forEach { option ->
                            val label = option.label()
                            FilterChip(
                                selected = !keepWebsiteImage && icon == option,
                                onClick = { icon = option; keepWebsiteImage = false },
                                label = { Icon(option.vector(), contentDescription = label, modifier = Modifier.size(24.dp)) },
                                modifier = Modifier.weight(1f),
                            )
                        }
                    }
                }
                if (!valid) Text(stringResource(R.string.browser_bookmark_invalid), color = MaterialTheme.colorScheme.onSurfaceVariant,
                    style = MaterialTheme.typography.bodyMedium)
            }
        },
        confirmButton = { TextButton(onClick = { onSave(title, url, icon, keepWebsiteImage) }, enabled = valid) {
            Text(stringResource(R.string.browser_bookmark_save))
        } },
        dismissButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.action_cancel)) } },
    )
}
