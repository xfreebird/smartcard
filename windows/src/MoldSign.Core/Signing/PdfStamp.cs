using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace MoldSign.Core;

/// <summary>Closed, trusted stamp language; arbitrary wording cannot enter the PDF appearance.</summary>
public enum PdfStampLanguage { Ro, En, Ru }

public static class PdfStampText
{
    public static PdfStampLanguage CurrentLanguage => FromLocale(CultureInfo.CurrentUICulture.Name);
    public static PdfStampLanguage FromLocale(string? identifier) => identifier?.Split('-', '_')[0].ToLowerInvariant() switch
    {
        "en" => PdfStampLanguage.En,
        "ru" => PdfStampLanguage.Ru,
        _ => PdfStampLanguage.Ro
    };

    public static string[] Lines(this PdfStampLanguage language, string holder, DateTimeOffset date)
    {
        var timestamp = date.ToString("yyyy.MM.dd HH:mm:ss zzz", CultureInfo.InvariantCulture);
        return language switch
        {
            PdfStampLanguage.En => [$"Digitally signed by {holder}", $"Date: {timestamp}", "Reason: MoldSign Signature", "Location: Moldova", "EUROPEAN MOLDOVA", "Signed with eSemnBun"],
            PdfStampLanguage.Ru => [$"Подписано электронной подписью: {holder}", $"Дата: {timestamp}", "Причина: MoldSign Signature", "Место: Молдова", "ЕВРОПЕЙСКАЯ МОЛДОВА", "Подписано с eSemnBun"],
            _ => [$"Semnat digital de {holder}", $"Data: {timestamp}", "Motiv: MoldSign Signature", "Locație: Moldova", "MOLDOVA EUROPEANĂ", "Semnat cu eSemnBun"]
        };
    }
}

/// <summary>Fractions of the displayed CropBox from top-left; Page is zero-based. Null means invisible.</summary>
public sealed record PdfStampPlacement(int Page = 0, bool AllPages = false, double X = .06, double Y = .72,
                                       double Width = .40, double Height = .113, string? DocumentSHA256 = null, PdfStampLanguage? Language = null)
{
    public bool CanApplyTo(byte[] document) => StampPdf.CanApply(this, document);
    public PdfStampPlacement Resized(int corner, double dx, double dy)
    {
        if (corner is < 0 or > 3 || !double.IsFinite(dx) || !double.IsFinite(dy) || Width <= 0 || Height <= 0) return this;
        var right = corner % 2 == 1; var bottom = corner >= 2; var ratio = Height / Width;
        var horizontal = right ? dx : -dx; var vertical = (bottom ? dy : -dy) / ratio;
        var delta = Math.Abs(horizontal) >= Math.Abs(vertical) ? horizontal : vertical;
        var limit = Math.Min(right ? 1-X : X+Width, (bottom ? 1-Y : Y+Height) / ratio);
        var w = Math.Min(limit, Math.Max(Math.Min(.1,limit),Width+delta)); var h = w*ratio;
        return this with { X=right ? X : X+Width-w, Y=bottom ? Y : Y+Height-h, Width=w, Height=h };
    }
    internal void Validate()
    {
        if (Page < 0 || new[] { X, Y, Width, Height }.Any(n => !double.IsFinite(n)) || X < 0 || Y < 0 ||
            Width <= 0 || Height <= 0 || X + Width > 1.000001 || Y + Height > 1.000001)
            throw new CardException(CardErrorKind.Format, "The signature stamp must fit inside the page");
    }
}

/// <summary>Syntax reader for the uncompressed objects supported by the incremental signer. Source bytes are retained.</summary>
internal static class StampPdf
{
    // Resolve fields without rewriting the signed revision or dropping existing signatures.
    internal static string AppendSignatureField(string text, string form, int field)
    {
        try
        {
            var fields = Value(form, "/Fields") ?? throw Fail();
            if (!fields.StartsWith('[')) fields = ObjectText(text, Ref(fields));
            var updated = "[" + string.Join(" ", Refs(fields).Append(field).Select(n => $"{n} 0 R")) + "]";
            return Set(form, "/Fields", updated);
        }
        catch (CardException)
        {
            throw new CardException(CardErrorKind.Format, "Cannot resolve AcroForm /Fields safely");
        }
    }

    private static CardException Fail() => new(CardErrorKind.Format, "This PDF cannot be stamped safely (unsupported page structure)");
    private static List<string> Tokens(string s)
    {
        var result = new List<string>(); var i = 0;
        while (i < s.Length)
        {
            if (char.IsWhiteSpace(s[i])) { i++; continue; }
            if (s[i] == '%') { while (i < s.Length && s[i] != '\n' && s[i] != '\r') i++; continue; }
            var start = i;
            if (s[i] == '(')
            {
                var depth = 1; i++;
                while (i < s.Length && depth > 0)
                {
                    if (s[i] == '\\') { i += Math.Min(2, s.Length - i); continue; }
                    if (s[i] == '(') depth++; if (s[i] == ')') depth--; i++;
                }
            }
            else if (s[i] == '<' && i + 1 < s.Length && s[i + 1] != '<')
            { i++; while (i < s.Length && s[i] != '>') i++; if (i < s.Length) i++; }
            else if (i + 1 < s.Length && (s.Substring(i, 2) == "<<" || s.Substring(i, 2) == ">>")) i += 2;
            else if ("[]<>".Contains(s[i])) i++;
            else { i++; while (i < s.Length && !char.IsWhiteSpace(s[i]) && !"/[]<>()%".Contains(s[i])) i++; }
            result.Add(s[start..i]);
        }
        return result;
    }
    private static List<(string Key, string Value)> Entries(string dict)
    {
        var t = Tokens(dict); if (t.Count == 0 || t[0] != "<<") throw Fail();
        var result = new List<(string, string)>(); var i = 1;
        while (i < t.Count && t[i] != ">>")
        {
            var key = t[i++]; var start = i;
            if (!key.StartsWith('/') || key.Contains('#') || result.Any(e => e.Item1 == key) || i >= t.Count) throw Fail();
            if (t[i] == "<<" || t[i] == "[")
            {
                var depth = 0;
                do { if (t[i] == "<<" || t[i] == "[") depth++; if (t[i] == ">>" || t[i] == "]") depth--; i++; } while (i < t.Count && depth > 0);
                if (depth != 0) throw Fail();
            }
            else if (i + 2 < t.Count && int.TryParse(t[i], out _) && int.TryParse(t[i + 1], out _) && t[i + 2] == "R") i += 3;
            else i++;
            result.Add((key, string.Join(" ", t.GetRange(start, i - start))));
        }
        if (i != t.Count - 1 || t[^1] != ">>") throw Fail(); return result;
    }
    private static string? Value(string dict, string key)
    {
        var values = Entries(dict).Where(e => e.Key == key).ToArray(); if (values.Length > 1) throw Fail();
        return values.Length == 0 ? null : values[0].Value;
    }
    private static string Set(string dict, string key, string value) => "<< " + string.Join(" ", Entries(dict).Where(e => e.Key != key).Append((Key: key, Value: value)).Select(e => $"{e.Key} {e.Value}")) + " >>";
    private static int Ref(string value)
    {
        var t = Tokens(value); if (t.Count != 3 || t[1] != "0" || t[2] != "R" || !int.TryParse(t[0], out var n) || n <= 0) throw Fail(); return n;
    }
    private static List<int> Refs(string value)
    {
        var t = Tokens(value); if (t.Count < 2 || t[0] != "[" || t[^1] != "]" || (t.Count - 2) % 3 != 0) throw Fail();
        var result = new List<int>(); for (var i = 1; i < t.Count - 1; i += 3) result.Add(Ref(string.Join(" ", t.GetRange(i, 3)))); return result;
    }
    private static string ObjectText(string text, int n)
    {
        var matches = DocumentRegex.Matches(text, FormattableString.Invariant($@"(?<!\d){n}\s+0\s+obj\b")); if (matches.Count == 0) throw Fail();
        var start = matches[^1].Index + matches[^1].Length; var end = text.IndexOf("endobj", start, StringComparison.Ordinal);
        if (end < 0) throw Fail(); return text[start..end].Trim();
    }
    private sealed record Page(int Number, string Dictionary, double[] Box, int Rotation);
    private static List<Page> Pages(string text, string catalog)
    {
        if (text.Contains("/Encrypt", StringComparison.Ordinal)) throw Fail();
        var visited = new HashSet<int>(); var result = new List<Page>();
        void Walk(int n, Dictionary<string, string> inherited, int depth)
        {
            if (depth >= 100 || !visited.Add(n)) throw Fail();
            var dict = ObjectText(text, n); var props = new Dictionary<string, string>(inherited);
            foreach (var key in new[] { "/MediaBox", "/CropBox", "/Rotate", "/UserUnit" }) if (Value(dict, key) is { } v) props[key] = v;
            if (Value(dict, "/Type") == "/Pages") foreach (var child in Refs(Value(dict, "/Kids") ?? throw Fail())) Walk(child, props, depth + 1);
            else
            {
                if (Value(dict, "/Type") != "/Page") throw Fail();
                var box = props.GetValueOrDefault("/CropBox") ?? props.GetValueOrDefault("/MediaBox") ?? throw Fail();
                if (!box.StartsWith('[')) box = ObjectText(text, Ref(box));
                double[] Rectangle(string input)
                {
                    var raw = input.StartsWith('[') ? input : ObjectText(text, Ref(input));
                    var values = Tokens(raw);
                    if (values.Count != 6 || values[0] != "[" || values[^1] != "]") throw Fail();
                    var parsed = values.Skip(1).SkipLast(1).Select(v => double.Parse(v, CultureInfo.InvariantCulture)).ToArray();
                    if (parsed.Any(v => !double.IsFinite(v)) || parsed[2] <= parsed[0] || parsed[3] <= parsed[1]) throw Fail();
                    return parsed;
                }
                var numbers = Rectangle(box);
                if (props.TryGetValue("/MediaBox", out var media))
                {
                    var bounds = Rectangle(media);
                    numbers = [Math.Max(numbers[0], bounds[0]), Math.Max(numbers[1], bounds[1]), Math.Min(numbers[2], bounds[2]), Math.Min(numbers[3], bounds[3])];
                }
                var rotation = int.Parse(props.GetValueOrDefault("/Rotate", "0"), CultureInfo.InvariantCulture);
                if (numbers[2] <= numbers[0] || numbers[3] <= numbers[1] || rotation % 90 != 0 || !IsUnitScale(props.GetValueOrDefault("/UserUnit", "1"))) throw Fail();
                result.Add(new Page(n, dict, numbers, (rotation % 360 + 360) % 360));
            }
        }
        Walk(Ref(Value(catalog, "/Pages") ?? throw Fail()), [], 0); if (result.Count == 0) throw Fail(); return result;
    }
    public static bool CanApply(PdfStampPlacement placement, byte[] data)
    {
        try
        {
            using var processing = DocumentRegex.BeginProcessing();
            DocumentRegex.CheckLength(data.Length);
            var text = Encoding.Latin1.GetString(data);
            var roots = DocumentRegex.Matches(text, @"/Root\s+(\d+)\s+0\s+R\b");
            if (roots.Count == 0) return false;
            var root = int.Parse(roots[^1].Groups[1].Value, CultureInfo.InvariantCulture);
            return placement.Page >= 0 && placement.Page < Pages(text, ObjectText(text, root)).Count;
        }
        catch (Exception error) when (error is CardException or FormatException or OverflowException) { return false; }
    }
    // Only unit scale is supported. The range comparison also rejects NaN and infinities.
    private static bool IsUnitScale(string userUnit) => Math.Abs(double.Parse(userUnit, CultureInfo.InvariantCulture) - 1) < 1e-9;
    // Baseline (PDF points from the stamp's bottom edge) of each of the six stamp text lines.
    private static readonly int[] LineBaselines = [82, 67, 52, 37, 16, 2];
    private static string Num(double n) => n.ToString("F5", CultureInfo.InvariantCulture);
    private static string Stream(byte[] bytes, string extra = "")
    {
        var hex = Convert.ToHexString(bytes) + ">"; return $"<< /Length {hex.Length} /Filter /ASCIIHexDecode {extra} >>\nstream\n{hex}\nendstream";
    }
    internal sealed record Appearance(string Field, List<(int Number, string Body)> Chunks, int Next);
    internal static Appearance Create(string text, string catalog, int field, int signature, int first, string name,
                                      PdfStampPlacement placement, string holder, DateTimeOffset date)
    {
        placement.Validate();
        if (Value(catalog, "/Perms") is not null) throw new CardException(CardErrorKind.Format, "A certified PDF cannot receive additional stamps");
        var pages = Pages(text, catalog); if (placement.Page >= pages.Count) throw Fail();
        var primary = pages[placement.Page];
        var selected = new List<Page> { primary }; if (placement.AllPages) selected.AddRange(pages.Where(p => p.Number != primary.Number));
        static byte[] Resource(string file)
        {
            using var source = typeof(StampPdf).Assembly.GetManifestResourceStream("MoldSign.Core.PDFStamp." + file) ?? throw new InvalidOperationException("Missing stamp font");
            using var data = new MemoryStream(); source.CopyTo(data); return data.ToArray();
        }
        var metrics = Encoding.UTF8.GetString(Resource("metrics.txt")).Split('\n', StringSplitOptions.RemoveEmptyEntries).Select(line => line.Split(' ').Select(v => int.Parse(v, CultureInfo.InvariantCulture)).ToArray()).ToDictionary(v => v[0], v => (Glyph: v[1], Advance: v[2]));
        var lines = (placement.Language ?? PdfStampText.CurrentLanguage).Lines(holder, date);
        var used = new SortedDictionary<int, (int Scalar, int Advance)>();
        var content = new StringBuilder("q 0.65 G 0.5 w 0.5 10 174 21 re S 0 g\n");
        for (var index = 0; index < lines.Length; index++)
        {
            var width = 0; var hex = new StringBuilder();
            foreach (var rune in lines[index].EnumerateRunes())
            {
                if (!metrics.TryGetValue(rune.Value, out var glyph)) throw new CardException(CardErrorKind.Format, "The signature font cannot display a character in the signer name");
                used[glyph.Glyph] = (rune.Value, glyph.Advance); width += glyph.Advance; hex.Append(glyph.Glyph.ToString("X4", CultureInfo.InvariantCulture));
            }
            var size = Math.Min(index == 5 ? 7.0 : 13.0, (index == 4 ? 164000.0 : 228000.0) / Math.Max(width, 1));
            content.Append(FormattableString.Invariant($"BT /F {Num(size)} Tf 1 0 0 1 {(index == 4 ? 5 : 0)} {LineBaselines[index]} Tm <{hex}> Tj ET\n"));
        }
        content.Append('Q');
        var mappings = used.Select(e => $"<{e.Key:X4}> <{Convert.ToHexString(Encoding.BigEndianUnicode.GetBytes(char.ConvertFromUtf32(e.Value.Scalar)))}>");
        var sections = string.Join("\n", mappings.Chunk(100).Select(group => $"{group.Length} beginbfchar\n" + string.Join("\n", group) + "\nendbfchar\n"));
        var cmap = "/CIDInit /ProcSet findresource begin 12 dict begin begincmap /CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def /CMapName /StampUnicode def /CMapType 2 def 1 begincodespacerange <0000> <FFFF> endcodespacerange\n" + sections + "endcmap CMapName currentdict /CMap defineresource pop end end";
        var b = first; var next = first + 5;
        var widths = string.Join(" ", used.Select(e => FormattableString.Invariant($"{e.Key} [{e.Value.Advance}]"))); var font = Resource("LiberationSerif-Regular.ttf");
        var descriptor = $"<< /Type /FontDescriptor /FontName /LiberationSerif-Regular /Flags 34 /FontBBox [-1000 -1000 2000 2000] /ItalicAngle 0 /Ascent 891 /Descent -216 /CapHeight 655 /StemV 80 /FontFile2 {b+1} 0 R >>";
        var descendant = $"<< /Type /Font /Subtype /CIDFontType2 /BaseFont /LiberationSerif-Regular /CIDSystemInfo << /Registry (Adobe) /Ordering (Identity) /Supplement 0 >> /CIDToGIDMap /Identity /W [{widths}] /FontDescriptor {b+4} 0 R >>";
        var chunks = new List<(int, string)> {
            (b, $"<< /Type /Font /Subtype /Type0 /BaseFont /LiberationSerif-Regular /Encoding /Identity-H /DescendantFonts [{b+3} 0 R] /ToUnicode {b+2} 0 R >>"),
            (b+1, Stream(font, $"/Length1 {font.Length}")), (b+2, Stream(Encoding.ASCII.GetBytes(cmap))),
            (b+3, descendant), (b+4, descriptor) };
        var kids = new List<int>(); var destination = "";
        foreach (var page in selected)
        {
            var widget = next; var ap = next + 1; next += 2; var isPrimary = page.Number == primary.Number; if (isPrimary) kids.Add(widget);
            var box = page.Box; var w = box[2]-box[0]; var h = box[3]-box[1];
            (double X, double Y) Point(double u, double v) => page.Rotation switch {
                90 => (box[0]+v*w, box[1]+u*h), 180 => (box[0]+(1-u)*w, box[1]+v*h),
                270 => (box[0]+(1-v)*w, box[1]+(1-u)*h), _ => (box[0]+u*w, box[1]+(1-v)*h) };
            var a = Point(placement.X, placement.Y); var z = Point(placement.X+placement.Width, placement.Y+placement.Height);
            var rect = string.Join(" ", new[] { Math.Min(a.X,z.X), Math.Min(a.Y,z.Y), Math.Max(a.X,z.X), Math.Max(a.Y,z.Y) }.Select(Num));
            var matrix = page.Rotation switch { 90 => "0 1 -1 0 96 0", 180 => "-1 0 0 -1 240 96", 270 => "0 -1 1 0 0 240", _ => "1 0 0 1 0 0" };
            var added = new List<int> { widget };
            if (isPrimary)
            {
                destination = $"[{page.Number} 0 R /FitR {rect}]";
                chunks.Add((widget, $"<< /Type /Annot /Subtype /Widget /Parent {field} 0 R /P {page.Number} 0 R /Rect [{rect}] /F 4 /AP << /N {ap} 0 R >> >>"));
            }
            else
            {
                chunks.Add((widget, $"<< /Type /Annot /Subtype /Stamp /P {page.Number} 0 R /Rect [{rect}] /F 4 /AP << /N {ap} 0 R >> >>"));
                added.Add(next);
                chunks.Add((next++, $"<< /Type /Annot /Subtype /Link /P {page.Number} 0 R /Rect [{rect}] /Border [0 0 0] /Dest {destination} >>"));
            }
            chunks.Add((ap, Stream(Encoding.ASCII.GetBytes(content.ToString()), $"/Type /XObject /Subtype /Form /BBox [0 0 240 96] /Matrix [{matrix}] /Resources << /Font << /F {b} 0 R >> >>")));
            var annots = Value(page.Dictionary, "/Annots") ?? "[]"; if (!annots.StartsWith('[')) annots = ObjectText(text, Ref(annots));
            chunks.Add((page.Number, Set(page.Dictionary, "/Annots", "[" + string.Join(" ", Refs(annots).Concat(added).Select(n => FormattableString.Invariant($"{n} 0 R"))) + "]")));
        }
        return new Appearance($"<< /FT /Sig /T ({name}) /V {signature} 0 R /Kids [" + string.Join(" ", kids.Select(n => FormattableString.Invariant($"{n} 0 R"))) + "] >>", chunks, next);
    }
}
