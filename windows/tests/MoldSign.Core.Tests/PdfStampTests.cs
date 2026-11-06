using Xunit;

namespace MoldSign.Core.Tests;

public sealed class PdfStampTests
{
    private const string Catalog = "<< /Type /Catalog /Pages 1 0 R >>";
    private const string Pdf = """
        1 0 obj << /Type /Pages /Kids [3 0 R 2 0 R] /Count 2 /MediaBox [0 0 600 800] /CropBox [20 30 520 730] /Rotate 90 >> endobj
        2 0 obj << /Type /Page /Parent 1 0 R /Rotate 0 /Annots [] >> endobj
        3 0 obj << /Type /Page /Parent 1 0 R /Annots 7 0 R /Private (keep /Annots [999 0 R]) >> endobj
        7 0 obj [8 0 R] endobj
        """;
    private static StampPdf.Appearance Create(PdfStampPlacement placement) => StampPdf.Create(Pdf, Catalog, 12, 10, 13,
        "Signature1", placement, "Ștefan Țurcanu Иванов", DateTimeOffset.UnixEpoch);

    [Fact]
    public void AllPagesUsesOneWidgetAndLinksBackToIt()
    {
        var a = Create(new PdfStampPlacement(AllPages: true, X: .1, Y: .2, Width: .4, Height: .1));
        var update = string.Join("\n", a.Chunks.Select(c => c.Body));
        Assert.Equal(1, update.Split("/Subtype /Widget").Length - 1);
        Assert.Equal(1, update.Split("/Subtype /Stamp").Length - 1);
        Assert.Contains("/Dest [3 0 R /FitR 120.00000 100.00000 170.00000 380.00000]", update);
        Assert.Contains("/Annots [8 0 R ", update);
        Assert.Contains("/Private (keep /Annots [999 0 R])", update);
        Assert.Contains("/Matrix [0 1 -1 0 96 0]", update);
        Assert.Contains("/V 10 0 R", a.Field);
    }
    [Fact]
    public void SinglePageDoesNotUpdateOtherPages()
    {
        var a = Create(new PdfStampPlacement(Page: 1));
        Assert.Contains(a.Chunks, c => c.Number == 2);
        Assert.DoesNotContain(a.Chunks, c => c.Number == 3);
    }
    [Fact]
    public void InvalidPlacementsFail()
    {
        foreach (var p in new[] { new PdfStampPlacement(Page: 3), new PdfStampPlacement(X: double.NaN), new PdfStampPlacement(X: .9) })
            Assert.Throws<CardException>(() => Create(p));
    }
}
