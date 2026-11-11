using MoldSign.Core;

namespace MoldSign.App.Services;

public sealed record CardDataResult(CertificateSummary? Certificate = null, CardErrorKind? Problem = null,
    bool Busy = false);
