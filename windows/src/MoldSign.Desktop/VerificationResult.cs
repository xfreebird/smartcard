using MoldSign.Core;

namespace MoldSign.Desktop;

public sealed record VerificationResult(VerificationStatus Status,
    IReadOnlyList<VerificationReport>? Reports = null, Verdict? Verdict = null, Exception? Error = null);
