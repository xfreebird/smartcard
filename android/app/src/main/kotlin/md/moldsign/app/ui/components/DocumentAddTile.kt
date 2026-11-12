package md.moldsign.app.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.UploadFile
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import md.moldsign.app.R
import md.moldsign.app.ui.theme.Tokens

/** The "Alege documentele" tile shrunk to one row, under the list once documents are added. */
@Composable
fun DocumentAddTile(onPick: () -> Unit, modifier: Modifier = Modifier) {
    val outline = MaterialTheme.colorScheme.primary.copy(alpha = 0.58f)
    OutlinedCard(
        onClick = onPick,
        modifier = modifier.fillMaxWidth().drawWithContent {
            drawContent()
            drawRoundRect(outline, topLeft = androidx.compose.ui.geometry.Offset(1.dp.toPx(), 1.dp.toPx()), size = androidx.compose.ui.geometry.Size(size.width - 2.dp.toPx(), size.height - 2.dp.toPx()), cornerRadius = androidx.compose.ui.geometry.CornerRadius(Tokens.RadiusCard.toPx()), style = Stroke(width = 1.dp.toPx(), pathEffect = PathEffect.dashPathEffect(floatArrayOf(6.dp.toPx(), 4.dp.toPx()))))
        },
        shape = RoundedCornerShape(Tokens.RadiusCard),
        // This remains a live document-picker action after the queue is populated. A full
        // container color makes that affordance distinct from disabled list content.
        colors = CardDefaults.outlinedCardColors(containerColor = MaterialTheme.colorScheme.primaryContainer),
        border = BorderStroke(0.dp, androidx.compose.ui.graphics.Color.Transparent),
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
