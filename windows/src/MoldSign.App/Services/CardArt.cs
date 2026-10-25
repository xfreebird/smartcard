using Windows.UI;

namespace MoldSign.App.Services;

/// <summary>
/// Fixed colors of the ID-card illustration (docs/10 §0.2b, UX-09). They depict a physical object, so they are the
/// same in light and dark mode; text on the card always uses these dark colors, never the theme's label color.
/// The guilloche hue is rotated ±20° per card from the first byte of the certificate SHA-1.
/// </summary>
internal static class CardArt
{
    public static readonly Color PaperStart = Rgb(0xF4EAF0);
    public static readonly Color PaperMiddle = Rgb(0xECEFF7);
    public static readonly Color PaperEnd = Rgb(0xF6F0E1);
    public static readonly Color GuillocheRose = Rgb(0xC6A3BC);
    public static readonly Color GuillocheBlue = Rgb(0xA7B6DA);
    public static readonly Color RosetteGold = Rgb(0xC9B48A);
    public static readonly Color Navy = Rgb(0x283A8C);
    public static readonly Color Burgundy = Rgb(0x9E2A3F);
    public static readonly Color ShieldStroke = Rgb(0x8C6A3A);
    public static readonly Color ShieldFill = Color.FromArgb(0x99, 0xE9, 0xD9, 0xB4); // #E9D9B4 at 60 %
    public static readonly Color ChipLight = Rgb(0xF5D27A);
    public static readonly Color ChipDark = Rgb(0xC9A23A);
    public static readonly Color ChipLine = Color.FromArgb(0x80, 0x8A, 0x6A, 0x1E);
    public static readonly Color PortraitTop = Rgb(0xD9DCE3);
    public static readonly Color PortraitBottom = Rgb(0xBFC4CF);
    public static readonly Color Silhouette = Rgb(0x8E95A3);
    public static readonly Color Label = Rgb(0x5A6070);
    public static readonly Color Value = Rgb(0x1E2230);
    public static readonly Color PlaceholderBar = Rgb(0xD3D7E0);
    public static readonly Color Hairline = Color.FromArgb(0x33, 0x1E, 0x22, 0x30);
    public static readonly Color StatusReady = Rgb(0x15803D);
    public static readonly Color StatusReading = Rgb(0xD97706);
    public static readonly Color StatusBusy = Rgb(0x2563EB);
    public static readonly Color StatusProblem = Rgb(0xB3261E);

    /// <summary>−20…+20 degrees from the first byte of the SHA-1 (hex); 0 when unknown.</summary>
    public static double HueOffset(string? sha1Hex) =>
        sha1Hex is { Length: >= 2 } && byte.TryParse(sha1Hex.AsSpan(0, 2), System.Globalization.NumberStyles.HexNumber, null, out var b)
            ? b / 255.0 * 40 - 20
            : 0;

    /// <summary>Rotates the hue of <paramref name="color"/> by <paramref name="degrees"/> (alpha kept).</summary>
    public static Color RotateHue(Color color, double degrees)
    {
        double r = color.R / 255.0, g = color.G / 255.0, b = color.B / 255.0;
        double max = Math.Max(r, Math.Max(g, b)), min = Math.Min(r, Math.Min(g, b));
        double l = (max + min) / 2, h = 0, s = 0;
        if (max > min)
        {
            var d = max - min;
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
            h = max == r ? (g - b) / d + (g < b ? 6 : 0) : max == g ? (b - r) / d + 2 : (r - g) / d + 4;
            h *= 60;
        }
        var rotated = FromHsl(h + degrees, s, l);
        return Color.FromArgb(color.A, rotated.R, rotated.G, rotated.B);
    }

    public static Color WithAlpha(Color color, double opacity) =>
        Color.FromArgb((byte)Math.Round(opacity * 255), color.R, color.G, color.B);

    private static Color Rgb(uint rgb) => Color.FromArgb(0xFF, (byte)(rgb >> 16), (byte)(rgb >> 8), (byte)rgb);

    private static Color FromHsl(double hue, double s, double l)
    {
        hue = ((hue % 360) + 360) % 360 / 360;
        var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        var p = 2 * l - q;
        static double Component(double p, double q, double t)
        {
            if (t < 0) t += 1;
            if (t > 1) t -= 1;
            if (t < 1.0 / 6) return p + (q - p) * 6 * t;
            if (t < 0.5) return q;
            if (t < 2.0 / 3) return p + (q - p) * (2.0 / 3 - t) * 6;
            return p;
        }
        return Color.FromArgb(0xFF,
            (byte)Math.Round(Component(p, q, hue + 1.0 / 3) * 255),
            (byte)Math.Round(Component(p, q, hue) * 255),
            (byte)Math.Round(Component(p, q, hue - 1.0 / 3) * 255));
    }
}
