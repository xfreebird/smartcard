package md.moldsign.app.ui.components


import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.pager.PageSize
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.runtime.key
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.snapshotFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CreditCard
import androidx.compose.material.icons.outlined.PhoneAndroid
import androidx.compose.material.icons.outlined.Usb
import androidx.compose.material.icons.rounded.Draw
import androidx.compose.material.icons.rounded.ExpandMore
import androidx.compose.material.icons.rounded.PriorityHigh
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material3.Button
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedCard
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.ripple
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.CustomAccessibilityAction
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.collapse
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.expand
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.onLongClick
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.min
import androidx.compose.ui.unit.times
import md.moldsign.app.R
import md.moldsign.app.presentation.errorText
import md.moldsign.app.ui.theme.Tokens
import md.moldsign.core.ReaderSlot
import md.moldsign.core.WalletCard
import md.moldsign.core.WalletState
import java.text.SimpleDateFormat
import java.util.Locale

private val ON_CARD = Color.White
private val ON_CARD_DIM = Color.White.copy(alpha = 0.82f)
private val ON_PAPER = Color(0xFF1E2230)
private val PAPER_HAIRLINE = Color(0x331E2230)
private val CHIP_GOLD = listOf(Color(0xFFFFD866), Color(0xFFF5B700), Color(0xFFD99A00))

/** Space for the selection ring (2 dp + gap) around every card, so collapsed and expanded cards are the same size. */
private val RING_PAD = 5.dp

/** Gap between cards in the expanded list (docs/10 §0.2b: 10–12). */
private val LIST_GAP = 11.dp

/** Expand / collapse / pick (docs/10 §0.2b: 250 ms ease-out; Compose follows "Remove animations"). */
private const val MOTION_MS = 250

/**
 * Horizontal reader-keyed carousel. A settled swipe selects the centered card; programmatic selection
 * scrolls to the same page. Empty wallets retain connection/reader guidance. Accessibility and keyboard
 * actions use the same selection callback as touch input.
 */
@Composable
fun CardWallet(
    wallet: WalletState,
    onSelect: (readerId: String) -> Unit,
    onReread: () -> Unit,
    onAllowUsb: (readerId: String?) -> Unit,
    modifier: Modifier = Modifier,
    large: Boolean = false,
    selectionEnabled: Boolean = true,
    onOpen: (() -> Unit)? = null,
) {
    val cards = wallet.cards
    val maxCard = if (large) 480.dp else 420.dp
    if (cards.isEmpty()) {
        BoxWithConstraints(modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
            Box(Modifier.width(min(maxWidth - 2 * Tokens.S6, maxCard))) { EmptyWalletCard(wallet, onAllowUsb) }
        }
        return
    }

    key(cards.map { it.readerId }) {
    val selectedIndex = cards.indexOfFirst { it.readerId == wallet.selectedCard?.readerId }.coerceAtLeast(0)
    val currentSelectedId by rememberUpdatedState(wallet.selectedCard?.readerId)
    val pager = rememberPagerState(initialPage = selectedIndex, pageCount = { cards.size })
    // A swipe commits the card only after settling, never midway through an interrupted gesture.
    LaunchedEffect(pager, cards.map { it.readerId }) {
        snapshotFlow { pager.settledPage }.distinctUntilChanged().collect { page ->
            cards.getOrNull(page)?.let { if (it.readerId != currentSelectedId) onSelect(it.readerId) }
        }
    }
    LaunchedEffect(selectedIndex) {
        if (!pager.isScrollInProgress && pager.currentPage != selectedIndex) pager.animateScrollToPage(selectedIndex)
    }
    Column(modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
        BoxWithConstraints(Modifier.widthIn(max = maxCard + 2 * Tokens.S4).fillMaxWidth().padding(horizontal = Tokens.S4)) {
            val pageWidth = min(maxWidth, maxCard)
            HorizontalPager(
            state = pager,
            userScrollEnabled = selectionEnabled,
            pageSize = PageSize.Fixed(pageWidth),
            key = { cards.getOrNull(it)?.readerId ?: "removed-$it" },
            contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = (maxWidth - pageWidth) / 2),
            pageSpacing = 12.dp,
            modifier = Modifier.fillMaxWidth(),
        ) { i ->
            val card = cards.getOrNull(i) ?: return@HorizontalPager
            WalletCardItem(
                card = card, index = i, cards = cards, selected = i == selectedIndex,
                expanded = true, large = large, canOpen = onOpen != null,
                onTap = { if (selectionEnabled) { if (i != selectedIndex) onSelect(card.readerId) else onOpen?.invoke() } },
                onPick = { index -> if (selectionEnabled) cards.getOrNull(index)?.let { onSelect(it.readerId) } },
                onToggle = {}, onReread = onReread,
            )
        }
        }
        if (cards.size > 1) Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier.padding(vertical = 8.dp),
        ) {
            repeat(cards.size) { index ->
                val label = stringResource(R.string.action_sign_with, holderOrReader(cards[index]))
                Box(Modifier.size(28.dp).clickable(enabled = selectionEnabled, onClickLabel = label) {
                    onSelect(cards[index].readerId)
                }.semantics {
                    contentDescription = label
                    role = Role.Button
                    selected = index == selectedIndex
                }, contentAlignment = Alignment.Center) {
                Box(Modifier.size(7.dp).background(
                    if (index == selectedIndex) MaterialTheme.colorScheme.primary
                    else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.3f),
                    CircleShape,
                ))
                }
            }
        }
    }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun WalletCardItem(
    card: WalletCard,
    index: Int,
    cards: List<WalletCard>,
    selected: Boolean,
    expanded: Boolean,
    large: Boolean,
    canOpen: Boolean,
    onTap: () -> Unit,
    onPick: (Int) -> Unit,
    onToggle: () -> Unit,
    onReread: () -> Unit,
) {
    var contextMenu by remember { mutableStateOf(false) }
    val haptics = LocalHapticFeedback.current
    val multi = cards.size > 1
    val ring by animateColorAsState(
        if (expanded && selected) MaterialTheme.colorScheme.primary else Color.Transparent,
        tween(MOTION_MS),
        label = "ring",
    )
    val description = if (expanded) {
        stringResource(R.string.action_sign_with, holderOrReader(card))
    } else {
        cardDescription(card, index, cards.size)
    }
    val nextLabel = stringResource(R.string.action_next_card)
    val previousLabel = stringResource(R.string.action_previous_card)
    val rereadLabel = stringResource(R.string.action_reread)
    val openLabel = stringResource(R.string.nav_card)
    // Compose maps `selected` to checked/not checked; the state description makes TalkBack say "selectat".
    val selectionState = stringResource(if (selected) R.string.wallet_selected else R.string.wallet_not_selected)
    val openMenu = {
        haptics.performHapticFeedback(HapticFeedbackType.LongPress)
        contextMenu = true
    }

    BoxWithConstraints(
        Modifier
            .fillMaxWidth()
            .border(2.dp, ring, RoundedCornerShape(Tokens.RadiusCard + RING_PAD))
            .padding(RING_PAD),
    ) {
        val w = maxWidth
        val h = w / Tokens.IdCardRatio
        IdCardFace(
            card = card,
            showReader = w >= 330.dp,
            reserveDisclosure = false,
            usedForSigning = expanded && selected,
            modifier = Modifier
                .clearAndSetSemantics {
                    contentDescription = description
                    if (expanded) {
                        role = Role.Button
                        this.selected = selected
                        stateDescription = selectionState
                        onClick(description) { onTap(); true }
                    } else {
                        liveRegion = LiveRegionMode.Polite
                        if (canOpen) onClick(openLabel) { onTap(); true }
                        customActions = buildList {
                            if (index < cards.size - 1) add(CustomAccessibilityAction(nextLabel) { onPick(index + 1); true })
                            if (index > 0) add(CustomAccessibilityAction(previousLabel) { onPick(index - 1); true })
                            add(CustomAccessibilityAction(rereadLabel) { onReread(); true })
                        }
                    }
                    onLongClick(rereadLabel) { openMenu(); true }
                }
                .onKeyEvent { e ->
                    if (expanded || e.type != KeyEventType.KeyDown) return@onKeyEvent false
                    when (e.key) {
                        Key.DirectionRight -> { if (index < cards.size - 1) onPick(index + 1); true }
                        Key.DirectionLeft -> { if (index > 0) onPick(index - 1); true }
                        else -> false
                    }
                }
                .combinedClickable(onClick = onTap, onLongClick = openMenu),
        )
        if (multi && selected && !expanded) {
            DisclosureButton(
                expanded = expanded,
                count = cards.size,
                diameter = 0.085f * w,
                onToggle = onToggle,
                modifier = Modifier.offset(x = 0.935f * w - 24.dp, y = 0.5f * h - 24.dp),
            )
        }
        DropdownMenu(expanded = contextMenu, onDismissRequest = { contextMenu = false }) {
            DropdownMenuItem(
                text = { Text(rereadLabel) },
                leadingIcon = { Icon(Icons.Rounded.Refresh, contentDescription = null) },
                onClick = {
                    contextMenu = false
                    onReread()
                },
            )
            cards.forEachIndexed { i, other ->
                if (i == index) return@forEachIndexed
                DropdownMenuItem(
                    text = { Text(stringResource(R.string.action_sign_with, holderOrReader(other))) },
                    leadingIcon = { Icon(Icons.Rounded.Draw, contentDescription = null) },
                    onClick = {
                        contextMenu = false
                        onPick(i)
                    },
                )
            }
        }
    }
}

/**
 * The round disclosure button (docs/10 §0.2b): 85 % white fill + hairline, chevron right → down. The visible circle is
 * 0.085 W; the touch target around it is 48 dp.
 */
@Composable
private fun DisclosureButton(expanded: Boolean, count: Int, diameter: Dp, onToggle: () -> Unit, modifier: Modifier = Modifier) {
    // Chevron points to the reading direction when collapsed, down when expanded.
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    val angle by animateFloatAsState(if (expanded) 0f else if (rtl) 90f else -90f, tween(MOTION_MS), label = "chevron")
    val label = pluralStringResource(R.plurals.wallet_choose_card, count, count)
    val state = stringResource(if (expanded) R.string.state_expanded else R.string.state_collapsed)
    Box(
        modifier
            .size(48.dp)
            .clickable(
                interactionSource = null,
                indication = ripple(bounded = false, radius = 24.dp),
                role = Role.Button,
                onClick = onToggle,
            )
            .semantics {
                contentDescription = label
                stateDescription = state
                if (expanded) collapse { onToggle(); true } else expand { onToggle(); true }
            },
        contentAlignment = Alignment.Center,
    ) {
        Box(
            Modifier
                .size(diameter)
                .background(Color.White.copy(alpha = 0.85f), CircleShape)
                .border(0.75.dp, PAPER_HAIRLINE, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                Icons.Rounded.ExpandMore,
                contentDescription = null,
                tint = ON_PAPER,
                modifier = Modifier.size(diameter * 0.78f).rotate(angle),
            )
        }
    }
}

@Composable
private fun holderOrReader(card: WalletCard): String = card.certificate?.commonName ?: card.readerName

/** "{holder}, card de identitate, valabil până la …, {i} din {n}" (+ the reading / problem line). */
@Composable
private fun cardDescription(card: WalletCard, index: Int, count: Int): String {
    val cert = card.certificate
    val problem = card.problem
    return when {
        problem != null -> stringResource(R.string.wallet_problem_description, card.readerName, errorText(problem), index + 1, count)
        cert == null -> stringResource(R.string.wallet_reading_description, card.readerName, index + 1, count)
        else -> stringResource(
            R.string.wallet_card_description,
            cert.commonName,
            SimpleDateFormat("dd.MM.yyyy", Locale.ROOT).format(cert.notAfter),
            index + 1,
            count,
        )
    }
}

/** Gold contact chip, drawn (no bitmap). */
@Composable
private fun ChipGraphic(modifier: Modifier = Modifier, outline: Color? = null) {
    Canvas(modifier) {
        val r = CornerRadius(size.height * 0.18f)
        if (outline != null) {
            drawRoundRect(outline, cornerRadius = r, style = Stroke(1.5.dp.toPx()))
            return@Canvas
        }
        drawRoundRect(Brush.linearGradient(CHIP_GOLD, Offset.Zero, Offset(size.width, size.height)), cornerRadius = r)
        val line = Color(0x66704F00)
        val w = 1.dp.toPx()
        drawLine(line, Offset(size.width * 0.5f, size.height * 0.18f), Offset(size.width * 0.5f, size.height * 0.82f), w)
        drawLine(line, Offset(0f, size.height * 0.36f), Offset(size.width * 0.34f, size.height * 0.36f), w)
        drawLine(line, Offset(0f, size.height * 0.64f), Offset(size.width * 0.34f, size.height * 0.64f), w)
        drawLine(line, Offset(size.width * 0.66f, size.height * 0.36f), Offset(size.width, size.height * 0.36f), w)
        drawLine(line, Offset(size.width * 0.66f, size.height * 0.64f), Offset(size.width, size.height * 0.64f), w)
        drawRoundRect(line, Offset(size.width * 0.34f, size.height * 0.3f), Size(size.width * 0.32f, size.height * 0.4f), CornerRadius(3f), style = Stroke(w))
    }
}

// ------------------------------------------------------------------ empty states (cards too)

@Composable
private fun EmptyWalletCard(wallet: WalletState, onAllowUsb: (String?) -> Unit) {
    val permission = wallet.readers.firstOrNull { it.state == ReaderSlot.State.PermissionRequired }
    val empty = wallet.readers.firstOrNull { it.state == ReaderSlot.State.Empty }
    val broken = wallet.readers.firstOrNull { it.state == ReaderSlot.State.Error }
    when {
        wallet.readers.isEmpty() -> ConnectReaderCard()
        permission != null -> PlaceholderCard {
            ChipGraphic(Modifier.size(width = 42.dp, height = 32.dp), outline = MaterialTheme.colorScheme.outline)
            Spacer(Modifier.weight(1f))
            Text(stringResource(R.string.usb_permission_title), style = MaterialTheme.typography.titleMedium)
            Text(permission.name, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(Modifier.height(Tokens.S2))
            Button(onClick = { onAllowUsb(permission.id) }) { Text(stringResource(R.string.action_allow)) }
        }
        empty != null -> PlaceholderCard {
            ChipGraphic(Modifier.size(width = 42.dp, height = 32.dp), outline = MaterialTheme.colorScheme.outline)
            Spacer(Modifier.weight(1f))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Outlined.CreditCard, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                Spacer(Modifier.width(Tokens.S2))
                Text(stringResource(R.string.wallet_insert_title), style = MaterialTheme.typography.titleLarge)
            }
            Text(
                stringResource(R.string.wallet_insert_body, empty.name),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        broken != null -> ErrorFace(
            title = stringResource(R.string.wallet_reader_error_title),
            body = stringResource(R.string.wallet_reader_error_body),
            caption = broken.name,
        )
        else -> ConnectReaderCard()
    }
}

/** Reader attached, no card: a solid placeholder in the card's shape. */
@Composable
private fun PlaceholderCard(content: @Composable ColumnScope.() -> Unit) {
    val outline = MaterialTheme.colorScheme.outline
    val fill = MaterialTheme.colorScheme.surfaceContainerLow
    Column(
        Modifier
            .fillMaxWidth()
            .aspectRatio(Tokens.IdCardRatio)
            .drawWithCache {
                val corner = CornerRadius(Tokens.RadiusCard.toPx())
                val stroke = Stroke(width = 1.5.dp.toPx())
                onDrawBehind {
                    drawRoundRect(fill, cornerRadius = corner)
                    drawRoundRect(outline, cornerRadius = corner, style = stroke)
                }
            }
            .semantics(mergeDescendants = true) {}
            .padding(Tokens.S4),
    ) { content() }
}

/** No reader: phone ⋯ reader connector illustration. */
@Composable
private fun ConnectReaderCard() {
    OutlinedCard(
        modifier = Modifier.fillMaxWidth().aspectRatio(Tokens.IdCardRatio).semantics(mergeDescendants = true) {},
        shape = RoundedCornerShape(Tokens.RadiusCard),
        colors = CardDefaults.outlinedCardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerLow),
    ) {
        Column(
            Modifier.fillMaxSize().padding(Tokens.S4),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            val tint = MaterialTheme.colorScheme.primary
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Outlined.PhoneAndroid, contentDescription = null, tint = tint, modifier = Modifier.size(40.dp))
                Connector(tint, Modifier.width(64.dp).height(12.dp))
                Icon(Icons.Outlined.Usb, contentDescription = null, tint = tint, modifier = Modifier.size(40.dp))
                Connector(tint, Modifier.width(28.dp).height(12.dp))
                Icon(Icons.Outlined.CreditCard, contentDescription = null, tint = MaterialTheme.colorScheme.outline, modifier = Modifier.size(36.dp).alpha(0.8f))
            }
            Spacer(Modifier.height(Tokens.S4))
            Text(stringResource(R.string.wallet_connect_title), style = MaterialTheme.typography.titleLarge)
            Text(
                stringResource(R.string.wallet_connect_body),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
            )
        }
    }
}

@Composable
private fun Connector(color: Color, modifier: Modifier) {
    Canvas(modifier) {
        val y = size.height / 2
        drawLine(
            color.copy(alpha = 0.7f), Offset(4.dp.toPx(), y), Offset(size.width - 4.dp.toPx(), y), 2.dp.toPx(),
        )
    }
}

/** Red-tinted face for a reader that fails (no card to draw). */
@Composable
private fun ErrorFace(title: String, body: String, caption: String) {
    ElevatedCard(
        modifier = Modifier.fillMaxWidth().aspectRatio(Tokens.IdCardRatio).semantics(mergeDescendants = true) {},
        shape = RoundedCornerShape(Tokens.RadiusCard),
    ) {
        Column(
            Modifier
                .fillMaxSize()
                .background(Brush.linearGradient(listOf(Color.hsl(356f, 0.62f, 0.42f), Color.hsl(342f, 0.66f, 0.26f))))
                .padding(Tokens.S4),
        ) {
            Row {
                Spacer(Modifier.weight(1f))
                Surface(shape = CircleShape, color = Color.White) {
                    Icon(Icons.Rounded.PriorityHigh, contentDescription = null, tint = Tokens.DangerLight, modifier = Modifier.padding(4.dp).size(20.dp))
                }
            }
            Spacer(Modifier.weight(1f))
            Text(title, style = MaterialTheme.typography.titleMedium, color = ON_CARD)
            Text(body, style = MaterialTheme.typography.bodyMedium, color = ON_CARD_DIM)
            Spacer(Modifier.height(Tokens.S1))
            Text(caption, style = MaterialTheme.typography.labelSmall, color = ON_CARD_DIM)
        }
    }
}
