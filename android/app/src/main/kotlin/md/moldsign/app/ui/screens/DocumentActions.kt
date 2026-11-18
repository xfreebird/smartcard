package md.moldsign.app.ui.screens

import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.OpenInNew
import androidx.compose.material.icons.outlined.LockOpen
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import md.moldsign.app.R

internal fun Context.openDocument(uri: Uri, name: String) {
    launchDocumentIntent(Intent(Intent.ACTION_VIEW).setDataAndType(uri, mimeOf(name))
        .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
}

internal fun Context.shareDocument(uri: Uri, name: String) {
    val share = Intent(Intent.ACTION_SEND).setType(mimeOf(name))
        .putExtra(Intent.EXTRA_STREAM, uri)
        .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    share.clipData = ClipData.newUri(contentResolver, name, uri)
    launchDocumentIntent(Intent.createChooser(share, null))
}

private fun Context.launchDocumentIntent(intent: Intent) {
    runCatching { startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }.onFailure {
        Toast.makeText(this, R.string.saved_unavailable, Toast.LENGTH_SHORT).show()
    }
}

@Composable
internal fun DocumentShareButton(uri: Uri, name: String) {
    val context = LocalContext.current
    IconButton(onClick = { context.shareDocument(uri, name) }) {
        Icon(Icons.Outlined.Share, contentDescription = stringResource(R.string.action_share))
    }
}

@Composable
internal fun DocumentDetailActions(uri: Uri, name: String, decrypt: (() -> Unit)? = null) {
    val context = LocalContext.current
    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        FilledTonalButton(onClick = decrypt ?: { context.openDocument(uri, name) }) {
            Icon(if (decrypt == null) Icons.AutoMirrored.Outlined.OpenInNew else Icons.Outlined.LockOpen,
                contentDescription = null, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(8.dp))
            Text(stringResource(if (decrypt == null) R.string.action_open else R.string.protect_decrypt))
        }
        TextButton(onClick = { context.shareDocument(uri, name) }) {
            Icon(Icons.Outlined.Share, contentDescription = null, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(8.dp))
            Text(stringResource(R.string.action_share))
        }
    }
}
