namespace MoldSign.App.Controls;

/// <summary>Render-ready identity and placeholder data. No device or certificate objects.</summary>
public sealed record IdentityCardContent
{
    public bool IsCard { get; init; }
    public bool IsErrorPlaceholder { get; init; }
    public string? Reader { get; init; }
    public string? Surname { get; init; }
    public string? GivenNames { get; init; }
    public string? ValidUntil { get; init; }
    public string? Issuer { get; init; }
    public double HueOffset { get; init; }
    public CardStatusTone Tone { get; init; }
    public string StatusText { get; init; } = "";
    public bool IsSelected { get; init; }
    public bool UsedForSigning { get; init; }
    public string AccessibilityLabel { get; init; } = "";
    public string PlaceholderGlyph { get; init; } = "";
    public string PlaceholderTitle { get; init; } = "";
    public string PlaceholderMessage { get; init; } = "";
    public IdentityCardLabels Labels { get; init; } = new("", "", "", "", "", "", "", "");
}
