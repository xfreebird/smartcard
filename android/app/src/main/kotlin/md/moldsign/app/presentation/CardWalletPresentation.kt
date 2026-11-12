package md.moldsign.app.presentation

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import md.moldsign.app.R
import md.moldsign.app.ui.components.CardWalletContent
import md.moldsign.app.ui.components.EmptyWalletContent
import md.moldsign.app.ui.components.IdentityCardContent
import md.moldsign.core.ReaderSlot
import md.moldsign.core.WalletState
import java.text.SimpleDateFormat
import java.util.Locale

@Composable
fun WalletState.toCardWalletContent(): CardWalletContent {
    val content = cards.mapIndexed { index, card ->
        val cert = card.certificate
        val problem = card.problem?.let { errorText(it) }
        val (surname, given) = cert?.nameParts ?: ("" to "")
        val description = when {
            problem != null -> stringResource(R.string.wallet_problem_description, card.readerName, problem, index + 1, cards.size)
            cert == null -> stringResource(R.string.wallet_reading_description, card.readerName, index + 1, cards.size)
            else -> stringResource(R.string.wallet_card_description, cert.commonName,
                SimpleDateFormat("dd.MM.yyyy", Locale.ROOT).format(cert.notAfter), index + 1, cards.size)
        }
        IdentityCardContent(card.readerId, card.readerName, cert?.commonName ?: card.readerName,
            surname, given, cert?.let { SimpleDateFormat("dd MM yyyy", Locale.ROOT).format(it.notAfter) }.orEmpty(),
            cert?.issuerCommonName ?: "MDQSign", cert != null, problem, cardHueShift(cert?.sha1Hex), description)
    }
    val permission = readers.firstOrNull { it.state == ReaderSlot.State.PermissionRequired }
    val empty = readers.firstOrNull { it.state == ReaderSlot.State.Empty }
    val broken = readers.firstOrNull { it.state == ReaderSlot.State.Error }
    val placeholder = when {
        permission != null -> EmptyWalletContent.Permission(permission.id, permission.name)
        empty != null -> EmptyWalletContent.Insert(empty.name)
        broken != null -> EmptyWalletContent.Error(broken.name)
        else -> EmptyWalletContent.Connect
    }
    return CardWalletContent(content, selectedCard?.readerId, placeholder)
}

internal fun cardHueShift(sha1: String?): Float =
    sha1?.takeIf { it.length >= 2 }?.take(2)?.toIntOrNull(16)?.let { it / 255f * 40f - 20f } ?: 0f
