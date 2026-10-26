using System.Globalization;
using Microsoft.UI.Text;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Automation;
using Microsoft.UI.Xaml.Automation.Peers;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using MoldSign.App.Services;
using Windows.Foundation;
using Windows.UI;
using Path = Microsoft.UI.Xaml.Shapes.Path;

namespace MoldSign.App.Controls;

/// <summary>
/// One wallet slot drawn at width W (docs/10 §0.2b, UX-09): the stylized Moldovan identity card (pastel paper,
/// guilloche waves and a rosette, bilingual headings, a NEUTRAL shield outline (never the coat of arms), the chip,
/// a grey portrait frame with a silhouette, the certificate's fields, a status strip), or a dashed empty-state card.
/// It shows only data from the signing certificate: no photo, no document number, no MRZ, no IDNP.
/// All geometry is relative to W (H = W / 1.586) so the face scales from the flyout to the Card page.
/// Raw for UI Automation: <see cref="CardWallet"/> is the one accessible element.
/// </summary>
internal sealed class IdCardFace : Grid
{
    public const double AspectRatio = 1.586;

    private static readonly CultureInfo s_ro = CultureInfo.GetCultureInfo("ro-RO");

    /// <param name="item">The slot to draw.</param>
    /// <param name="width">W in effective pixels.</param>
    /// <param name="signing">The app is signing with this card (blue status).</param>
    /// <param name="withDisclosure">The disclosure button sits on this card (centre 0.935 W): values stop at 0.88 W.</param>
    /// <param name="usedForSigning">Selected card in the expanded list: a ready card shows "✓ Folosit pentru semnare".</param>
    public IdCardFace(WalletCardItem item, double width, bool signing, bool withDisclosure, bool usedForSigning)
    {
        var height = width / AspectRatio;
        Width = width;
        Height = height;
        AutomationProperties.SetAccessibilityView(this, AccessibilityView.Raw);
        if (item.Kind == WalletItemKind.Card) BuildCard(item, width, height, signing, withDisclosure, usedForSigning);
        else BuildPlaceholder(item, width);
    }

    // MARK: - ID card

    private void BuildCard(WalletCardItem item, double w, double h, bool signing, bool withDisclosure, bool usedForSigning)
    {
        var canvas = new Canvas { Width = w, Height = h, Clip = new RectangleGeometry { Rect = new Rect(0, 0, w, h) } };
        Children.Add(new Border
        {
            CornerRadius = new CornerRadius(0.045 * w),
            BorderBrush = Solid(CardArt.Hairline),
            BorderThickness = new Thickness(1),
            Background = Gradient(new Point(0, 0), new Point(1, 1), CardArt.PaperStart, CardArt.PaperMiddle, CardArt.PaperEnd),
            Child = canvas,
        });

        var certificate = item.Certificate;
        AddGuilloche(canvas, w, h, CardArt.HueOffset(certificate?.Sha1));

        // Headings: left navy, right burgundy, the neutral shield centred between them, the chip top-right.
        Place(canvas, Heading("REPUBLICA MOLDOVA", "REPUBLIC OF MOLDOVA", CardArt.Navy, w, 0.37 * w), 0.045 * w, 0.06 * h);
        var shieldHeight = 0.07 * w;
        Place(canvas, Shield(shieldHeight), 0.48 * w - shieldHeight * 0.41, 0.06 * h);
        Place(canvas, Heading("CARTE DE IDENTITATE", "IDENTITY CARD", CardArt.Burgundy, w, 0.32 * w), 0.52 * w, 0.06 * h);
        Place(canvas, Chip(w), 0.855 * w, 0.06 * h);
        Place(canvas, Portrait(0.24 * w, 0.60 * h, 0.02 * w), 0.045 * w, 0.30 * h);

        // Fields (certificate data only). Before the read finishes: placeholder bars instead of values.
        // With the disclosure button on the card, values stop at 0.88 W so they never run under it.
        var x = 0.32 * w;
        var right = (withDisclosure ? 0.88 : 0.955) * w;
        var (surname, given) = certificate?.NameParts() ?? ("", "");
        var until = certificate?.NotAfter.ToLocalTime().ToString("dd MM yyyy", CultureInfo.InvariantCulture);
        AddField(canvas, w, "Numele/Surname", certificate is null ? null : surname, x, 0.30 * h, right - x, 0.42);
        AddField(canvas, w, "Prenumele/Given name(s)", certificate is null ? null : given, x, 0.47 * h, right - x, 0.32);
        AddField(canvas, w, "Valabil până la/Valid until", until, x, 0.64 * h, 0.33 * w, 0.22);
        // The disclosure (0.43–0.57 H) only shares rows with the names; the issuer row keeps the full width.
        AddField(canvas, w, "Emitent/Issuer", certificate?.IssuerName, 0.66 * w, 0.64 * h, 0.955 * w - 0.66 * w, 0.2);

        AddStatusStrip(canvas, item, w, h, x, signing, usedForSigning);
    }

    /// <summary>12 sine waves alternating rose/blue at 35 %, and a gold rosette of 8 ellipses at 25 %.</summary>
    private static void AddGuilloche(Canvas canvas, double w, double h, double hueOffset)
    {
        var rose = new PathGeometry();
        var blue = new PathGeometry();
        var amplitude = 0.04 * h;
        var period = 0.55 * w;
        var step = Math.Max(1.5, w / 160);
        for (var i = 0; i < 12; i++)
        {
            var baseline = h * (i + 0.5) / 12;
            var phase = i * 0.35;
            var figure = new PathFigure { StartPoint = new Point(0, baseline + amplitude * Math.Sin(phase)), IsFilled = false };
            var line = new PolyLineSegment();
            for (var px = step; px <= w + step; px += step)
                line.Points.Add(new Point(px, baseline + amplitude * Math.Sin(2 * Math.PI * px / period + phase)));
            figure.Segments.Add(line);
            (i % 2 == 0 ? rose : blue).Figures.Add(figure);
        }
        canvas.Children.Add(new Path
        {
            Data = rose, Stroke = Solid(CardArt.RotateHue(CardArt.GuillocheRose, hueOffset)), StrokeThickness = 0.7, Opacity = 0.35,
        });
        canvas.Children.Add(new Path
        {
            Data = blue, Stroke = Solid(CardArt.RotateHue(CardArt.GuillocheBlue, hueOffset)), StrokeThickness = 0.7, Opacity = 0.35,
        });

        var center = new Point(0.78 * w, 0.62 * h);
        // Separate paths avoid WinUI's null geometry in GeometryGroup's stroke-mask renderer on Windows 10.
        for (var i = 0; i < 8; i++)
        {
            canvas.Children.Add(new Path
            {
                Data = new EllipseGeometry { Center = center, RadiusX = 0.22 * w, RadiusY = 0.07 * w },
                RenderTransform = new RotateTransform { Angle = i * 22.5, CenterX = center.X, CenterY = center.Y },
                Stroke = Solid(CardArt.RosetteGold),
                StrokeThickness = 0.8,
                Opacity = 0.25,
            });
        }
    }

    /// <summary>Bold letter-spaced first line + regular second line, a 1 px rule under each; shrinks to fit.</summary>
    private static FrameworkElement Heading(string first, string second, Color color, double w, double maxWidth)
    {
        var panel = new StackPanel { Spacing = 0.006 * w };
        panel.Children.Add(Ruled(new TextBlock
        {
            Text = first, FontSize = 0.036 * w, FontWeight = FontWeights.Bold, CharacterSpacing = 40, Foreground = Solid(color),
        }, color));
        panel.Children.Add(Ruled(new TextBlock { Text = second, FontSize = 0.026 * w, Foreground = Solid(color) }, color));
        return new Viewbox
        {
            MaxWidth = maxWidth, Stretch = Stretch.Uniform, StretchDirection = StretchDirection.DownOnly, Child = panel,
        };
    }

    private static Border Ruled(TextBlock text, Color color) => new()
    {
        BorderBrush = Solid(color), BorderThickness = new Thickness(0, 0, 0, 1), Padding = new Thickness(0, 0, 0, 1), Child = text,
    };

    /// <summary>A plain heater-shield outline in bronze: a neutral emblem, deliberately not the state coat of arms.</summary>
    private static Path Shield(double height)
    {
        var width = height * 0.82;
        var figure = new PathFigure { StartPoint = new Point(0, 0), IsClosed = true, IsFilled = true };
        figure.Segments.Add(new LineSegment { Point = new Point(width, 0) });
        figure.Segments.Add(new LineSegment { Point = new Point(width, height * 0.42) });
        figure.Segments.Add(new BezierSegment
        {
            Point1 = new Point(width, height * 0.78), Point2 = new Point(width * 0.62, height * 0.92), Point3 = new Point(width * 0.5, height),
        });
        figure.Segments.Add(new BezierSegment
        {
            Point1 = new Point(width * 0.38, height * 0.92), Point2 = new Point(0, height * 0.78), Point3 = new Point(0, height * 0.42),
        });
        var geometry = new PathGeometry();
        geometry.Figures.Add(figure);
        return new Path { Data = geometry, Stroke = Solid(CardArt.ShieldStroke), StrokeThickness = 1, Fill = Solid(CardArt.ShieldFill) };
    }

    /// <summary>The gold contact chip, 0.10 W × 0.075 W, with its contact lines.</summary>
    private static Border Chip(double w)
    {
        var chipWidth = 0.10 * w;
        var chipHeight = 0.075 * w;
        var lines = new Canvas { Width = chipWidth, Height = chipHeight };
        foreach (var fx in new[] { 0.34, 0.66 })
            Place(lines, new Rectangle { Width = 1, Height = chipHeight, Fill = Solid(CardArt.ChipLine) }, chipWidth * fx, 0);
        Place(lines, new Rectangle { Width = chipWidth, Height = 1, Fill = Solid(CardArt.ChipLine) }, 0, chipHeight * 0.5);
        return new Border
        {
            Width = chipWidth,
            Height = chipHeight,
            CornerRadius = new CornerRadius(0.012 * w),
            Background = Gradient(new Point(0, 0), new Point(1, 1), CardArt.ChipLight, CardArt.ChipDark),
            BorderBrush = Solid(CardArt.ChipLine),
            BorderThickness = new Thickness(0.5),
            Child = lines,
        };
    }

    /// <summary>Grey portrait frame with a neutral head-and-shoulders silhouette (never a photo).</summary>
    private static Border Portrait(double width, double height, double radius)
    {
        var silhouette = new Canvas { Width = width, Height = height, Clip = new RectangleGeometry { Rect = new Rect(0, 0, width, height) } };
        var headWidth = 0.42 * width;
        var headHeight = headWidth * 1.2;
        var headTop = 0.17 * height;
        Place(silhouette, new Ellipse { Width = headWidth, Height = headHeight, Fill = Solid(CardArt.Silhouette) },
              (width - headWidth) / 2, headTop);
        var shoulders = 0.96 * width;
        Place(silhouette, new Ellipse { Width = shoulders, Height = shoulders * 0.8, Fill = Solid(CardArt.Silhouette) },
              (width - shoulders) / 2, headTop + headHeight + 0.03 * height);
        return new Border
        {
            Width = width,
            Height = height,
            CornerRadius = new CornerRadius(radius),
            Background = Gradient(new Point(0, 0), new Point(0, 1), CardArt.PortraitTop, CardArt.PortraitBottom),
            Child = silhouette,
        };
    }

    /// <summary>Bilingual label + UPPERCASE value (diacritics kept); a grey bar while the certificate is being read.</summary>
    private static void AddField(Canvas canvas, double w, string label, string? value, double x, double y, double width,
                                 double barFraction)
    {
        var labelSize = Math.Max(0.024 * w, 7);
        var valueSize = Math.Max(0.046 * w, 11);
        Place(canvas, new TextBlock
        {
            Text = label, FontSize = labelSize, Foreground = Solid(CardArt.Label), MaxWidth = width, TextTrimming = TextTrimming.CharacterEllipsis,
        }, x, y);
        var valueTop = y + labelSize * 1.3;
        if (value is null)
        {
            Place(canvas, new Rectangle
            {
                Width = barFraction * w, Height = valueSize * 0.62, RadiusX = 2, RadiusY = 2, Fill = Solid(CardArt.PlaceholderBar),
            }, x, valueTop + valueSize * 0.3);
            return;
        }
        Place(canvas, new TextBlock
        {
            Text = value.ToUpper(s_ro),
            FontSize = valueSize,
            FontWeight = FontWeights.SemiBold,
            Foreground = Solid(CardArt.Value),
            MaxWidth = width,
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap,
        }, x, valueTop);
    }

    /// <summary>
    /// Status strip: dot + one line (ready / reading / signing / the problem), the reader on large sizes. The selected
    /// card of the expanded list shows the check badge "✓ Folosit pentru semnare" instead of "Pregătit pentru semnare".
    /// </summary>
    private static void AddStatusStrip(Canvas canvas, WalletCardItem item, double w, double h, double x, bool signing,
                                       bool usedForSigning)
    {
        var ready = item.Problem is null && !signing && item.Certificate is not null;
        var (dot, text, textColor) = item.Problem is { } problem
            ? (CardArt.StatusProblem, AppState.ErrorText(problem), CardArt.StatusProblem)
            : signing ? (CardArt.StatusBusy, Loc.Get("Light_Busy"), CardArt.Value)
            : item.Certificate is null ? (CardArt.StatusReading, Loc.Get("Light_Reading"), CardArt.Value)
            : (CardArt.StatusReady, Loc.Get(usedForSigning ? "Wallet_UsedForSigning" : "Wallet_StatusReady"), CardArt.Value);

        var top = 0.80 * h;
        var textSize = Math.Max(0.034 * w, 10);
        var dotSize = Math.Max(0.022 * w, 7);
        var textX = x + dotSize + 0.015 * w;
        var right = 0.955 * w;
        if (ready && usedForSigning)
        {
            // Check badge: a green disc with a white check mark, in place of the status dot.
            var badge = Math.Max(0.034 * w, 11);
            textX = x + badge + 0.015 * w;
            Place(canvas, new Grid
            {
                Width = badge,
                Height = badge,
                Children =
                {
                    new Ellipse { Fill = Solid(dot) },
                    new FontIcon { Glyph = "\uE73E", FontSize = badge * 0.62, Foreground = Solid(Color.FromArgb(0xFF, 0xFF, 0xFF, 0xFF)) },
                },
            }, x, top + (textSize * 1.33 - badge) / 2);
        }
        else
        {
            Place(canvas, new Ellipse { Width = dotSize, Height = dotSize, Fill = Solid(dot) }, x, top + (textSize * 1.33 - dotSize) / 2);
        }
        Place(canvas, new TextBlock
        {
            Text = text,
            FontSize = textSize,
            FontWeight = FontWeights.SemiBold,
            Foreground = Solid(textColor),
            MaxWidth = right - textX,
            TextTrimming = TextTrimming.CharacterEllipsis,
        }, textX, top);
        if (w >= 360 && item.Reader is { } reader)
        {
            Place(canvas, new TextBlock
            {
                Text = reader, FontSize = Math.Max(0.026 * w, 9), Foreground = Solid(CardArt.Label), MaxWidth = right - textX,
                TextTrimming = TextTrimming.CharacterEllipsis,
            }, textX, top + textSize * 1.35);
        }
    }

    // MARK: - Empty states (theme colors: they are not the physical card)

    private void BuildPlaceholder(WalletCardItem item, double w)
    {
        var radius = 0.045 * w;
        if (item.Kind == WalletItemKind.MuteCard)
        {
            Children.Add(new Border
            {
                CornerRadius = new CornerRadius(radius),
                Background = WindowHelpers.ThemeBrush("DangerSoftBrush"),
                BorderBrush = WindowHelpers.ThemeBrush("DangerBrush"),
                BorderThickness = new Thickness(1.5),
            });
        }
        else
        {
            Children.Add(new Rectangle
            {
                RadiusX = radius,
                RadiusY = radius,
                Stroke = WindowHelpers.ThemeBrush("ControlStrongStrokeColorDefaultBrush"),
                StrokeDashArray = [4, 3],
                StrokeThickness = 1.5,
            });
        }
        var content = new StackPanel { Padding = new Thickness(16), Spacing = 6, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
        content.Children.Add(new FontIcon
        {
            Glyph = item.PlaceholderGlyph, FontSize = 28, HorizontalAlignment = HorizontalAlignment.Center,
            Foreground = WindowHelpers.ThemeBrush("TextFillColorSecondaryBrush"),
        });
        content.Children.Add(new TextBlock
        {
            Text = item.PlaceholderTitle, FontSize = 15, FontWeight = FontWeights.SemiBold, HorizontalAlignment = HorizontalAlignment.Center,
        });
        content.Children.Add(new TextBlock
        {
            Text = item.PlaceholderMessage, FontSize = 12, TextAlignment = TextAlignment.Center, TextWrapping = TextWrapping.Wrap,
            HorizontalAlignment = HorizontalAlignment.Center, Foreground = WindowHelpers.ThemeBrush("TextFillColorSecondaryBrush"),
        });
        Children.Add(content);
    }

    // MARK: - Helpers

    private static void Place(Canvas canvas, UIElement element, double x, double y)
    {
        Canvas.SetLeft(element, x);
        Canvas.SetTop(element, y);
        canvas.Children.Add(element);
    }

    private static SolidColorBrush Solid(Color color) => new(color);

    private static LinearGradientBrush Gradient(Point start, Point end, params Color[] colors)
    {
        var brush = new LinearGradientBrush { StartPoint = start, EndPoint = end };
        for (var i = 0; i < colors.Length; i++)
            brush.GradientStops.Add(new GradientStop { Color = colors[i], Offset = colors.Length == 1 ? 0 : (double)i / (colors.Length - 1) });
        return brush;
    }
}
