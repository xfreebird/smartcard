using MoldSign.Core;

namespace MoldSign.App.Services;

/// <summary>One document to sign and the format chosen for it on the Sign page (PDF: PAdES-T or XAdES; others: XAdES).</summary>
public sealed record DocumentJob(string Path, SignatureFormat Format, PdfStampPlacement? Stamp = null);
