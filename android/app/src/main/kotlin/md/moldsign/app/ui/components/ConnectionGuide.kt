package md.moldsign.app.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.PhoneAndroid
import androidx.compose.material.icons.outlined.Usb
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedCard
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import md.moldsign.app.R
import md.moldsign.app.ui.theme.Tokens

/** ConnectionGuide (docs/10 §3, mobile): adapter tiles; on Android the USB-C OTG tile leads. */
@Composable
fun ConnectionGuide(modifier: Modifier = Modifier) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(Tokens.S3)) {
        Text(stringResource(R.string.guide_title), style = MaterialTheme.typography.titleMedium)
        AdapterTile(Icons.Outlined.Usb, stringResource(R.string.guide_usbc_title), stringResource(R.string.guide_usbc_body))
        AdapterTile(Icons.Outlined.PhoneAndroid, stringResource(R.string.guide_micro_title), stringResource(R.string.guide_micro_body))
    }
}

@Composable
private fun AdapterTile(icon: ImageVector, title: String, body: String) {
    OutlinedCard(shape = RoundedCornerShape(Tokens.RadiusCard), modifier = Modifier.fillMaxWidth()) {
        Row(Modifier.padding(Tokens.S4), verticalAlignment = Alignment.CenterVertically) {
            Icon(icon, contentDescription = null, modifier = Modifier.size(32.dp), tint = MaterialTheme.colorScheme.primary)
            Spacer(Modifier.width(Tokens.S4))
            Column {
                Text(title, style = MaterialTheme.typography.titleSmall)
                Text(body, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}
