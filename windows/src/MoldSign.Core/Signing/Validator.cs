namespace MoldSign.Core;

/// <summary>Overall verdict shown by the VerdictBadge (docs/10 §3).</summary>
public enum Verdict
{
    Valid,
    Invalid,
    /// <summary>"Nu poate fi confirmată": integrity OK but chain/time could not be established.</summary>
    Indeterminate,
}

/// <summary>One signature's report; mirrors Swift <c>Validator.Report</c>.</summary>
public sealed record VerificationReport
{
    /// <summary>"PAdES" or "XAdES".</summary>
    public required string Kind { get; init; }
    /// <summary>Signature field name or Signature Id.</summary>
    public required string Name { get; init; }
    public required string Signer { get; init; }
    public bool ContentIntact { get; init; }
    public bool SignatureValid { get; init; }
    public bool ChainTrusted { get; init; }
    public string SigningTime { get; init; } = "";
    public string? TimestampTime { get; init; }
    /// <summary>"PAdES-B-T", "XAdES-C"…</summary>
    public string Level { get; init; } = "";

    public Verdict Verdict => !(ContentIntact && SignatureValid)
        ? Verdict.Invalid
        : ChainTrusted ? Verdict.Valid : Verdict.Indeterminate;
}

/// <summary>Offline validator (docs/05-offline-validation.md). Port target: <c>Validation.swift</c>.</summary>
public sealed class Validator
{
    /// <summary>Every signature in a PDF (ByteRange, CMS, RSA, manual chain to mdtrustca).</summary>
    public IReadOnlyList<VerificationReport> ValidatePdf(byte[] pdf) =>
        // TODO(WIN-01): port Validator.validatePDF / validateCMS / verifiesOfflineChain.
        throw new NotImplementedException("TODO(WIN-01): PAdES validation not ported yet.");

    /// <summary>XAdES signature with its referenced files (basename → bytes) for detached references.</summary>
    public IReadOnlyList<VerificationReport> ValidateXades(byte[] xml, IReadOnlyDictionary<string, byte[]> referencedFiles) =>
        // TODO(WIN-01): port Validator.validateXAdES (inclusive c14n tricks: inject inherited ns, expand empties).
        throw new NotImplementedException("TODO(WIN-01): XAdES validation not ported yet.");
}
