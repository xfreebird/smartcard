package md.moldsign.app.ui.screens

import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import md.moldsign.app.R
import md.moldsign.app.presentation.errorText
import md.moldsign.app.ui.theme.LocalStatusColors
import md.moldsign.app.ui.theme.Tokens
import md.moldsign.core.WalletCard
import java.text.DateFormat

@Composable
internal fun CardDetails(card: WalletCard) = CardDetails(card.certificate, card.problem, card.readerName)

@Composable
internal fun CardDetails(cert: md.moldsign.core.CertificateSummary?, problem: Throwable? = null, readerName: String? = null) {
    val itemColors = ListItemDefaults.colors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow)
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
        shape = RoundedCornerShape(Tokens.RadiusCard),
    ) {
        @Composable
        fun row(label: Int, value: String, divider: Boolean = true) {
            if (divider) HorizontalDivider(Modifier.padding(horizontal = Tokens.S4))
            ListItem(
                overlineContent = { Text(stringResource(label)) },
                headlineContent = { Text(value, maxLines = 2, overflow = TextOverflow.MiddleEllipsis) },
                colors = itemColors,
            )
        }
        when {
            problem != null -> ListItem(
                leadingContent = { Icon(Icons.Outlined.ErrorOutline, contentDescription = null, tint = LocalStatusColors.current.danger) },
                headlineContent = { Text(stringResource(R.string.wallet_error_title)) },
                supportingContent = { Text(errorText(problem)) },
                colors = itemColors,
            )
            cert == null -> ListItem(
                leadingContent = { CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.5.dp) },
                headlineContent = { Text(stringResource(R.string.status_reading)) },
                colors = itemColors,
            )
            else -> {
                val fmt = DateFormat.getDateInstance(DateFormat.MEDIUM)
                row(R.string.card_holder, cert.commonName, divider = false)
                row(R.string.card_issuer, cert.issuerCommonName ?: cert.issuerDn)
                row(R.string.card_validity, "${fmt.format(cert.notBefore)} – ${fmt.format(cert.notAfter)}")
                row(R.string.card_serial, cert.serialHex)
                row(R.string.card_fingerprint, cert.sha1Hex.chunked(4).joinToString(" "))
            }
        }
        if (readerName != null && (cert != null || problem != null)) HorizontalDivider(Modifier.padding(horizontal = Tokens.S4))
        if (readerName != null) ListItem(
            overlineContent = { Text(stringResource(R.string.card_reader)) },
            headlineContent = { Text(readerName) },
            colors = itemColors,
        )
    }
}
