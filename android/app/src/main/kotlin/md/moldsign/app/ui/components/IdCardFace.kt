package md.moldsign.app.ui.components

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.CacheDrawScope
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.RoundRect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.dp
import md.moldsign.app.R
import md.moldsign.app.presentation.errorText
import md.moldsign.app.ui.theme.Tokens
import md.moldsign.core.WalletCard
import java.text.SimpleDateFormat
import java.util.Locale
import kotlin.math.PI
import kotlin.math.max
import kotlin.math.sin

/*
 * docs/10 §0.2b (UX-09): the card drawn as a stylized illustration of the Moldovan identity card. It shows only
 * certificate data: NO photo, NO state coat of arms (a neutral shield outline instead), NO document number,
 * NO MRZ, NO IDNP. Fixed colors in light and dark (a physical object, like a Wallet pass) with a hairline border
 * and a shadow. All positions and sizes are fractions of the card width W (H = W / 1.618034).
 */

private val PAPER = listOf(Color(0xFFF4EAF0), Color(0xFFECEFF7), Color(0xFFF6F0E1))
private val GUILLOCHE_ROSE = Color(0xFFC6A3BC)
private val GUILLOCHE_BLUE = Color(0xFFA7B6DA)
private val ROSETTE_GOLD = Color(0xFFC9B48A)
private val NAVY = Color(0xFF283A8C)
private val BURGUNDY = Color(0xFF9E2A3F)
private val BRONZE = Color(0xFF8C6A3A)
private val SHIELD_FILL = Color(0xFFE9D9B4)
private val PORTRAIT = listOf(Color(0xFFD9DCE3), Color(0xFFBFC4CF))
private val SILHOUETTE = Color(0xFF8E95A3)
private val LABEL = Color(0xFF5A6070)
private val VALUE = Color(0xFF1E2230)
private val CHIP_GOLD = listOf(Color(0xFFFFD866), Color(0xFFF5B700), Color(0xFFD99A00))
private val HAIRLINE = Color(0x2E1E2230)

// Fixed status colors (the face never follows the theme): docs/10 §2 light tokens.
private val READY = Tokens.SuccessLight
private val READING = Tokens.WarningLight
private val PROBLEM = Tokens.DangerLight
private val USED = Tokens.BrandLight // #2350D8, the selected card in the expanded list

// Printed bilingual on the physical card, so not translated.
private const val HEAD_RO = "REPUBLICA MOLDOVA"
private const val HEAD_EN = "REPUBLIC OF MOLDOVA"
private const val DOC_RO = "CARTE DE IDENTITATE"
private const val DOC_EN = "IDENTITY CARD"
private const val L_SURNAME = "Numele/Surname"
private const val L_GIVEN = "Prenumele/Given name(s)"
private const val L_VALID = "Valabil până la/Valid until"
private const val L_ISSUER = "Emitent/Issuer"

/** Corner radius 0.045 W, expressed as a percent of the shorter side (H) for RoundedCornerShape. */
val IdCardShape = RoundedCornerShape(percent = 7)

/** What the status strip says (docs/10 §0.2b). [Used] = "✓ Folosit pentru semnare" on the selected card of the list. */
private enum class Strip { Ready, Used, Reading, Problem }

/**
 * One card face. [usedForSigning] marks the selected card of the expanded wallet list: a ready card's strip then
 * reads "✓ Folosit pentru semnare" in brand blue instead of "● Pregătit pentru semnare" (no separate badge; a card
 * still reading or in error keeps that line). [showReader] adds the reader name under the status line (large
 * sizes); [reserveDisclosure]
 * stops the field values at 0.88 W so they never run under the disclosure button the wallet overlays at
 * (0.935 W, 0.50 H) (docs/10 §0.2b, UX-10 revised).
 */
@Composable
fun IdCardFace(
    card: WalletCard,
    modifier: Modifier = Modifier,
    showReader: Boolean = true,
    reserveDisclosure: Boolean = false,
    usedForSigning: Boolean = false,
) {
    val measurer = rememberTextMeasurer()
    val cert = card.certificate
    val problem = card.problem
    val strip = when {
        problem != null -> Strip.Problem
        cert == null -> Strip.Reading
        usedForSigning -> Strip.Used
        else -> Strip.Ready
    }
    val statusText = when (strip) {
        Strip.Ready -> stringResource(R.string.card_ready_to_sign)
        Strip.Used -> stringResource(R.string.wallet_used_for_signing)
        Strip.Reading -> stringResource(R.string.status_reading)
        Strip.Problem -> errorText(problem!!)
    }
    val (surname, given) = cert?.nameParts ?: ("" to "")
    val validUntil = cert?.let { SimpleDateFormat("dd MM yyyy", Locale.ROOT).format(it.notAfter) }.orEmpty()
    val issuer = cert?.issuerCommonName ?: "MDQSign"
    val hueShift = guillocheShift(cert?.sha1Hex)
    // Placeholder bars pulse while the certificate is read (stops with "Remove animations").
    val pulse = if (strip == Strip.Reading) {
        val t = rememberInfiniteTransition(label = "reading")
        val a by t.animateFloat(0.08f, 0.18f, infiniteRepeatable(tween(700), RepeatMode.Reverse), label = "bars")
        a
    } else {
        0.1f
    }

    Box(
        modifier
            .fillMaxWidth()
            .aspectRatio(Tokens.IdCardRatio)
            .shadow(6.dp, IdCardShape, clip = false)
            .clip(IdCardShape)
            .border(1.dp, HAIRLINE, IdCardShape)
            .drawWithCache {
                val face = layoutFace(
                    measurer, surname.uppercase(), given.uppercase(), validUntil, issuer.uppercase(), statusText,
                    card.readerName.takeIf { showReader }, reserveDisclosure, hueShift,
                )
                onDrawBehind { drawFace(face, strip, cert == null, pulse) }
            },
    )
}

/** First certificate byte → guilloche hue rotation in [-20°, +20°]. */
private fun guillocheShift(sha1Hex: String?): Float {
    val b = sha1Hex?.takeIf { it.length >= 2 }?.substring(0, 2)?.toIntOrNull(16) ?: return 0f
    return b / 255f * 40f - 20f
}

private fun Color.rotateHue(degrees: Float): Color {
    if (degrees == 0f) return this
    val hsv = FloatArray(3)
    android.graphics.Color.colorToHSV(toArgb(), hsv)
    hsv[0] = ((hsv[0] + degrees) % 360f + 360f) % 360f
    return Color(android.graphics.Color.HSVToColor(hsv))
}

/** Everything measured once per size (drawWithCache). */
private class FaceLayout(
    val w: Float,
    val h: Float,
    val waves: List<Pair<Path, Color>>,
    val waveStroke: Float,
    val headLeft: List<TextLayoutResult>,
    val headRight: List<TextLayoutResult>,
    val headLeftX: Float,
    val headTop: Float,
    val emblemX: Float,
    val emblemW: Float,
    val headRightX: Float,
    val headBlockH: Float,
    val lineGap: Float,
    val labels: List<Pair<TextLayoutResult, Offset>>,
    val values: List<Pair<TextLayoutResult, Offset>>,
    val bars: List<Pair<Offset, Size>>,
    val status: TextLayoutResult,
    val statusAt: Offset,
    val reader: TextLayoutResult?,
    val readerAt: Offset,
    val dotCenter: Offset,
    val dotRadius: Float,
)

private fun CacheDrawScope.layoutFace(
    measurer: TextMeasurer,
    surname: String,
    given: String,
    validUntil: String,
    issuer: String,
    statusText: String,
    reader: String?,
    reserveDisclosure: Boolean,
    hueShift: Float,
): FaceLayout {
    val w = size.width
    val h = size.height

    // Guilloche: 12 sine waves (amplitude 0.04 H, period ≈ 0.55 W, phase step 0.35 rad), rose / blue alternating.
    val rose = GUILLOCHE_ROSE.rotateHue(hueShift).copy(alpha = 0.35f)
    val blue = GUILLOCHE_BLUE.rotateHue(hueShift).copy(alpha = 0.35f)
    val step = max(2f, w / 160f)
    val waves = (0 until 12).map { i ->
        val baseY = h * (i + 0.5f) / 12f
        val path = Path()
        var x = 0f
        while (x <= w + step) {
            val y = baseY + 0.04f * h * sin(2 * PI * x / (0.55f * w) + i * 0.35).toFloat()
            if (x == 0f) path.moveTo(x, y) else path.lineTo(x, y)
            x += step
        }
        path to if (i % 2 == 0) rose else blue
    }

    // Headings: left (navy) | neutral shield | right (burgundy), all left of the chip; scaled down to fit.
    val margin = 0.045f * w
    val chipX = w - margin
    val gap = 0.02f * w
    val emblemW = 0.055f * w
    fun heads(scale: Float): Pair<List<TextLayoutResult>, List<TextLayoutResult>> {
        val bold = TextStyle(fontSize = (0.036f * w * scale).toSp(), fontWeight = FontWeight.Bold, letterSpacing = (0.0025f * w * scale).toSp())
        val regular = TextStyle(fontSize = (0.026f * w * scale).toSp(), fontWeight = FontWeight.Normal)
        val left = listOf(measurer.measure(HEAD_RO, bold.copy(color = NAVY)), measurer.measure(HEAD_EN, regular.copy(color = NAVY)))
        val right = listOf(measurer.measure(DOC_RO, bold.copy(color = BURGUNDY)), measurer.measure(DOC_EN, regular.copy(color = BURGUNDY)))
        return left to right
    }
    val available = chipX - gap - margin
    var (left, right) = heads(1f)
    fun total(l: List<TextLayoutResult>, r: List<TextLayoutResult>) =
        l.maxOf { it.size.width } + gap + emblemW + gap + r.maxOf { it.size.width }
    val needed = total(left, right)
    if (needed > available) {
        val scaled = heads(available / needed * 0.98f)
        left = scaled.first
        right = scaled.second
    }
    val headTop = 0.06f * h
    val lineGap = 0.008f * w
    val headBlockH = left[0].size.height + lineGap + left[1].size.height + lineGap
    val emblemX = margin + left.maxOf { it.size.width } + gap
    val headRightX = emblemX + emblemW + gap

    // Fields from x 0.32 W, rows at 0.30 / 0.47 / 0.64 H; row 3 has a second column at 0.66 W.
    val x0 = 0.32f * w
    val x1 = 0.66f * w
    val labelStyle = TextStyle(color = LABEL, fontSize = (0.024f * w).toSp())
    val valueSize = 0.046f * w
    val rows = listOf(0.30f * h, 0.47f * h, 0.64f * h)
    val labels = mutableListOf<Pair<TextLayoutResult, Offset>>()
    val values = mutableListOf<Pair<TextLayoutResult, Offset>>()
    val bars = mutableListOf<Pair<Offset, Size>>()
    fun field(label: String, value: String, x: Float, y: Float, maxW: Float, barW: Float) {
        val l = measurer.measure(label, labelStyle, maxLines = 1, overflow = TextOverflow.Ellipsis, constraints = Constraints(maxWidth = maxW.toInt()))
        labels += l to Offset(x, y)
        val vy = y + l.size.height + 0.004f * h
        if (value.isEmpty()) {
            bars += Offset(x, vy + 0.006f * w) to Size(barW, 0.034f * w)
            return
        }
        // Long names shrink (down to 75 %) before they ellipsize.
        val natural = measurer.measure(value, TextStyle(fontSize = valueSize.toSp(), fontWeight = FontWeight.SemiBold), maxLines = 1)
        val fit = if (natural.size.width > maxW) max(0.75f, maxW / natural.size.width) else 1f
        val v = measurer.measure(
            value, TextStyle(color = VALUE, fontSize = (valueSize * fit).toSp(), fontWeight = FontWeight.SemiBold),
            maxLines = 1, overflow = TextOverflow.Ellipsis, constraints = Constraints(maxWidth = maxW.toInt()),
        )
        values += v to Offset(x, vy)
    }
    // Field values reserve the right-center contact-chip column.
    val valueRight = 0.825f * w
    val fullW = valueRight - x0
    val reading = surname.isEmpty() && given.isEmpty()
    field(L_SURNAME, if (reading) "" else surname.ifEmpty { "—" }, x0, rows[0], fullW, 0.36f * w)
    field(L_GIVEN, if (reading) "" else given.ifEmpty { "—" }, x0, rows[1], fullW, 0.28f * w)
    field(L_VALID, validUntil, x0, rows[2], x1 - x0 - gap, 0.22f * w)
    field(L_ISSUER, if (reading) "" else issuer, x1, rows[2], valueRight - x1, 0.18f * w)

    // Status strip: x from 0.32 W, y 0.80–0.95 H; dot + one line (+ reader caption on large sizes).
    val dotRadius = 0.011f * w
    val textX = x0 + dotRadius * 2 + 0.015f * w
    val rightLimit = w - margin
    val statusStyle = TextStyle(fontSize = (0.03f * w).toSp(), fontWeight = FontWeight.Medium)
    val status = measurer.measure(statusText, statusStyle, maxLines = 1, overflow = TextOverflow.Ellipsis, constraints = Constraints(maxWidth = max(1f, rightLimit - textX).toInt()))
    val readerLayout = reader?.let {
        measurer.measure(it, TextStyle(color = LABEL, fontSize = (0.022f * w).toSp()), maxLines = 1, overflow = TextOverflow.Ellipsis, constraints = Constraints(maxWidth = max(1f, rightLimit - textX).toInt()))
    }
    val stripTop = 0.80f * h
    val stripH = 0.15f * h
    val contentH = status.size.height + (readerLayout?.size?.height ?: 0)
    val statusY = stripTop + (stripH - contentH) / 2
    return FaceLayout(
        w, h, waves, max(1f, 0.6.dp.toPx()), left, right, margin, headTop, emblemX, emblemW, headRightX, headBlockH, lineGap,
        labels, values, bars, status, Offset(textX, statusY), readerLayout, Offset(textX, statusY + status.size.height),
        Offset(x0 + dotRadius, statusY + status.size.height / 2f), dotRadius,
    )
}

private fun DrawScope.drawFace(f: FaceLayout, strip: Strip, placeholders: Boolean, barAlpha: Float) {
    val w = f.w
    val h = f.h
    drawRect(Brush.linearGradient(PAPER, Offset.Zero, Offset(w, h)))
    f.waves.forEachIndexed { i, (path, color) -> drawPath(path, color, style = Stroke(width = f.waveStroke * if (i % 2 == 0) 1f else 1.35f)) }
    // Rosette: 8 ellipses around (0.78 W, 0.62 H), radius ≤ 0.22 W.
    val c = Offset(0.78f * w, 0.62f * h)
    val rosette = Stroke(width = f.waveStroke * 1.3f)
    for (k in 0 until 8) {
        rotate(k * 22.5f, pivot = c) {
            drawOval(ROSETTE_GOLD.copy(alpha = 0.25f), topLeft = Offset(c.x - 0.22f * w, c.y - 0.07f * w), size = Size(0.44f * w, 0.14f * w), style = rosette)
        }
    }

    // Headings with a 1 px rule under each line.
    val rule = max(1f, 0.8.dp.toPx())
    fun headBlock(lines: List<TextLayoutResult>, x: Float, color: Color) {
        var y = f.headTop
        lines.forEach { line ->
            drawText(line, topLeft = Offset(x, y))
            y += line.size.height
            drawLine(color.copy(alpha = 0.8f), Offset(x, y + f.lineGap / 2), Offset(x + line.size.width, y + f.lineGap / 2), rule)
            y += f.lineGap
        }
    }
    headBlock(f.headLeft, f.headLeftX, NAVY)
    headBlock(f.headRight, f.headRightX, BURGUNDY)
    drawShield(Offset(f.emblemX, f.headTop + (f.headBlockH - 0.07f * w) / 2), Size(f.emblemW, 0.07f * w))
    drawChip(Offset(0.855f * w, 0.5f * h - 0.05f * w / 1.618034f), Size(0.10f * w, 0.10f * w / 1.618034f))
    drawPortrait(Offset(0.045f * w, 0.30f * h), Size(0.18f * w, 0.18f * w * 5f / 3f), 0.02f * w)

    f.labels.forEach { (t, at) -> drawText(t, topLeft = at) }
    f.values.forEach { (t, at) -> drawText(t, topLeft = at) }
    if (placeholders) {
        f.bars.forEach { (at, size) -> drawRoundRect(VALUE.copy(alpha = barAlpha), at, size, CornerRadius(size.height / 2)) }
    }

    val color = when (strip) {
        Strip.Ready -> READY
        Strip.Used -> USED
        Strip.Reading -> READING
        Strip.Problem -> PROBLEM
    }
    if (strip == Strip.Used) {
        drawCheck(color, f.dotCenter, f.dotRadius * 1.35f)
    } else {
        drawCircle(color, f.dotRadius, f.dotCenter)
    }
    drawText(f.status, color = color, topLeft = f.statusAt)
    f.reader?.let { drawText(it, topLeft = f.readerAt) }
}

/** "✓" in place of the status dot, same footprint. */
private fun DrawScope.drawCheck(color: Color, center: Offset, r: Float) {
    val path = Path().apply {
        moveTo(center.x - 0.85f * r, center.y + 0.05f * r)
        lineTo(center.x - 0.25f * r, center.y + 0.65f * r)
        lineTo(center.x + 0.9f * r, center.y - 0.6f * r)
    }
    drawPath(path, color, style = Stroke(width = 0.42f * r, cap = StrokeCap.Round, join = StrokeJoin.Round))
}

/** Neutral heater-shield outline (never the state coat of arms). */
private fun DrawScope.drawShield(at: Offset, size: Size) {
    val (sw, sh) = size
    val path = Path().apply {
        moveTo(at.x, at.y)
        lineTo(at.x + sw, at.y)
        lineTo(at.x + sw, at.y + 0.45f * sh)
        cubicTo(at.x + sw, at.y + 0.78f * sh, at.x + 0.62f * sw, at.y + 0.92f * sh, at.x + 0.5f * sw, at.y + sh)
        cubicTo(at.x + 0.38f * sw, at.y + 0.92f * sh, at.x, at.y + 0.78f * sh, at.x, at.y + 0.45f * sh)
        close()
    }
    drawPath(path, SHIELD_FILL.copy(alpha = 0.6f))
    drawPath(path, BRONZE, style = Stroke(width = max(1f, 0.9.dp.toPx())))
    // An inner rule keeps it heraldic-looking without any charge.
    drawLine(BRONZE.copy(alpha = 0.6f), Offset(at.x + 0.18f * sw, at.y + 0.22f * sh), Offset(at.x + 0.82f * sw, at.y + 0.22f * sh), max(1f, 0.6.dp.toPx()))
}

/** The gold contact chip (v2), drawn. */
private fun DrawScope.drawChip(at: Offset, size: Size) {
    val r = CornerRadius(size.height * 0.18f)
    drawRoundRect(Brush.linearGradient(CHIP_GOLD, at, Offset(at.x + size.width, at.y + size.height)), at, size, r)
    drawRoundRect(Color(0x55704F00), at, size, r, style = Stroke(max(1f, 0.6.dp.toPx())))
    val line = Color(0x66704F00)
    val sw = max(1f, 0.8.dp.toPx())
    fun l(x1: Float, y1: Float, x2: Float, y2: Float) =
        drawLine(line, Offset(at.x + x1 * size.width, at.y + y1 * size.height), Offset(at.x + x2 * size.width, at.y + y2 * size.height), sw)
    // Eight pads: three on each side, two in the center. All separators meet a rail.
    l(0.32f, 0f, 0.32f, 1f)
    l(0.68f, 0f, 0.68f, 1f)
    for (y in listOf(1f / 3f, 2f / 3f)) {
        l(0f, y, 0.32f, y)
        l(0.68f, y, 1f, y)
    }
    l(0.32f, 0.5f, 0.68f, 0.5f)
}

/** Grey portrait frame with a neutral head-and-shoulders silhouette (never a photo). */
private fun DrawScope.drawPortrait(at: Offset, size: Size, radius: Float) {
    val frame = Path().apply { addRoundRect(RoundRect(at.x, at.y, at.x + size.width, at.y + size.height, CornerRadius(radius))) }
    clipPath(frame) {
        drawRect(Brush.verticalGradient(PORTRAIT, at.y, at.y + size.height), at, size)
        val cx = at.x + size.width / 2
        val unit = size.width
        drawCircle(SILHOUETTE, radius = 0.24f * unit, center = Offset(cx, at.y + 0.53f * unit))
        val bust = Path().apply {
            moveTo(cx - 0.44f * unit, at.y + 1.32f * unit)
            cubicTo(cx - 0.44f * unit, at.y + 1.04f * unit, cx - 0.23f * unit, at.y + 0.90f * unit, cx, at.y + 0.90f * unit)
            cubicTo(cx + 0.23f * unit, at.y + 0.90f * unit, cx + 0.44f * unit, at.y + 1.04f * unit, cx + 0.44f * unit, at.y + 1.32f * unit)
            close()
        }
        drawPath(bust, SILHOUETTE)
    }
    drawPath(frame, LABEL.copy(alpha = 0.25f), style = Stroke(max(1f, 0.6.dp.toPx())))
}
