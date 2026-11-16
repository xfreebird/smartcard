package md.moldsign.app.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// docs/10 §2 design tokens.
object Tokens {
    val BrandLight = Color(0xFF2350D8)
    val BrandDark = Color(0xFF7C9BFF)
    val BrandSoftLight = Color(0xFFE8EEFF)
    val BrandSoftDark = Color(0xFF1C2547)
    val AccentLight = Color(0xFFF5B700)
    val AccentDark = Color(0xFFFFCD3C)
    val SuccessLight = Color(0xFF15803D)
    val SuccessDark = Color(0xFF4ADE80)
    val WarningLight = Color(0xFFB45309)
    val WarningDark = Color(0xFFFBBF24)
    val DangerLight = Color(0xFFC62828)
    val DangerDark = Color(0xFFF87171)
    val SurfaceRaisedLight = Color(0xFFFFFFFF)
    val SurfaceRaisedDark = Color(0xFF1E1F24)

    /** Spacing scale 4, 8, 12, 16, 20, 24, 32. */
    val S1 = 4.dp
    val S2 = 8.dp
    val S3 = 12.dp
    val S4 = 16.dp
    val S5 = 20.dp
    val S6 = 24.dp
    val S8 = 32.dp

    val RadiusControl = 12.dp // M3 small
    val RadiusCard = 14.dp
    val RadiusSheet = 18.dp

    /** Stylized card illustration uses the golden ratio. */
    const val IdCardRatio = 1.618034f
}

/** Status light dot color (docs/10 §0.1); `null` = no dot (idle). Semantic tokens, never dynamic color. */
fun StatusColors.forTone(light: StatusTone): Color? = when (light) {
    StatusTone.Success -> success
    StatusTone.Warning -> warning
    StatusTone.Busy -> brand
    StatusTone.Danger -> danger
    StatusTone.Idle -> null
}

/** Semantic colors Material 3 has no slot for. */
@Immutable
data class StatusColors(
    val brand: Color,
    val brandSoft: Color,
    val accent: Color,
    val success: Color,
    val warning: Color,
    val danger: Color,
    val surfaceRaised: Color,
)

private val LightStatus = StatusColors(
    Tokens.BrandLight, Tokens.BrandSoftLight, Tokens.AccentLight, Tokens.SuccessLight,
    Tokens.WarningLight, Tokens.DangerLight, Tokens.SurfaceRaisedLight,
)
private val DarkStatus = StatusColors(
    Tokens.BrandDark, Tokens.BrandSoftDark, Tokens.AccentDark, Tokens.SuccessDark,
    Tokens.WarningDark, Tokens.DangerDark, Tokens.SurfaceRaisedDark,
)

val LocalStatusColors = staticCompositionLocalOf { LightStatus }

// Brand fallback schemes (no dynamic color before Android 12), tuned around #2350D8 / #7C9BFF.
private val BrandLightScheme: ColorScheme = lightColorScheme(
    primary = Tokens.BrandLight,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFDCE1FF),
    onPrimaryContainer = Color(0xFF00164F),
    secondary = Color(0xFF595D72),
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFDEE1F9),
    onSecondaryContainer = Color(0xFF161B2C),
    tertiary = Color(0xFF7A5900),
    tertiaryContainer = Color(0xFFFFDEA0),
    onTertiaryContainer = Color(0xFF261900),
    error = Tokens.DangerLight,
    background = Color(0xFFF5F5F7),
    surface = Color(0xFFF5F5F7),
    surfaceContainerLowest = Color.White,
    surfaceContainerLow = Color(0xFFF2F2F5),
    surfaceContainer = Color(0xFFEDEDF0),
    surfaceContainerHigh = Color(0xFFE7E7EB),
    surfaceContainerHighest = Color(0xFFE1E1E6),
    outline = Color(0xFF757680),
    outlineVariant = Color(0xFFC5C6D0),
)

private val BrandDarkScheme: ColorScheme = darkColorScheme(
    primary = Tokens.BrandDark,
    onPrimary = Color(0xFF002780),
    primaryContainer = Color(0xFF1C3BB0),
    onPrimaryContainer = Color(0xFFDCE1FF),
    secondary = Color(0xFFC2C5DD),
    onSecondary = Color(0xFF2B3042),
    secondaryContainer = Color(0xFF424659),
    onSecondaryContainer = Color(0xFFDEE1F9),
    tertiary = Tokens.AccentDark,
    tertiaryContainer = Color(0xFF5C4300),
    onTertiaryContainer = Color(0xFFFFDEA0),
    error = Tokens.DangerDark,
    background = Color(0xFF121318),
    surface = Color(0xFF121318),
    surfaceContainerLowest = Color(0xFF0D0E13),
    surfaceContainerLow = Color(0xFF1A1B21),
    surfaceContainer = Tokens.SurfaceRaisedDark,
    surfaceContainerHigh = Color(0xFF292A2F),
    surfaceContainerHighest = Color(0xFF34343A),
    outline = Color(0xFF8F909A),
    outlineVariant = Color(0xFF45464F),
)

private val AppTypography = Typography().let { t ->
    t.copy(
        titleLarge = t.titleLarge.copy(fontSize = 22.sp, fontWeight = FontWeight.SemiBold),
        titleMedium = t.titleMedium.copy(fontSize = 15.sp, fontWeight = FontWeight.SemiBold),
    )
}

private val AppShapes = Shapes(
    small = RoundedCornerShape(Tokens.RadiusControl),
    medium = RoundedCornerShape(Tokens.RadiusCard),
    large = RoundedCornerShape(Tokens.RadiusSheet),
)

/**
 * One brand palette for NFC, reader and document journeys. Dynamic color remains opt-in.
 * The semantic status colors stay on brand tokens either way.
 */
@Composable
fun MoldSignTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit,
) {
    val scheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val ctx = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(ctx) else dynamicLightColorScheme(ctx)
        }
        darkTheme -> BrandDarkScheme
        else -> BrandLightScheme
    }
    CompositionLocalProvider(LocalStatusColors provides if (darkTheme) DarkStatus else LightStatus) {
        MaterialTheme(colorScheme = scheme, typography = AppTypography, shapes = AppShapes, content = content)
    }
}
