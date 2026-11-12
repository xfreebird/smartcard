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

/** "Alege documentele": the phone's drop zone (docs/10 DropZone), an outlined card that opens the picker. */
@Composable
fun DocumentPickZone(
    onPick: () -> Unit,
    modifier: Modifier = Modifier,
    title: String = stringResource(R.string.sign_choose_title),
    body: String = stringResource(R.string.sign_choose_body),
    compact: Boolean = false,
) {
    val outline = MaterialTheme.colorScheme.primary.copy(alpha = 0.58f)
    OutlinedCard(
        onClick = onPick,
        modifier = modifier.fillMaxWidth().drawWithContent {
            drawContent()
            drawRoundRect(outline, topLeft = androidx.compose.ui.geometry.Offset(1.dp.toPx(), 1.dp.toPx()), size = androidx.compose.ui.geometry.Size(size.width - 2.dp.toPx(), size.height - 2.dp.toPx()), cornerRadius = androidx.compose.ui.geometry.CornerRadius(Tokens.RadiusCard.toPx()), style = Stroke(width = 1.dp.toPx(), pathEffect = PathEffect.dashPathEffect(floatArrayOf(6.dp.toPx(), 4.dp.toPx()))))
        },
        shape = RoundedCornerShape(Tokens.RadiusCard),
        colors = CardDefaults.outlinedCardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
        border = BorderStroke(0.dp, androidx.compose.ui.graphics.Color.Transparent),
    ) {
        Row(Modifier.fillMaxWidth().padding(if (compact) Tokens.S3 else Tokens.S6), verticalAlignment = Alignment.CenterVertically) {
            if (compact) Icon(Icons.Outlined.UploadFile, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.padding(end = Tokens.S3).size(32.dp))
            Column(Modifier.weight(1f), horizontalAlignment = if (compact) Alignment.Start else Alignment.CenterHorizontally) {
                if (!compact) {
                    Icon(Icons.Outlined.UploadFile, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(32.dp))
                    Spacer(Modifier.height(Tokens.S2))
                }
                Text(title, style = MaterialTheme.typography.titleMedium)
                Text(body, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = if (compact) TextAlign.Start else TextAlign.Center)
            }
        }
    }
}
