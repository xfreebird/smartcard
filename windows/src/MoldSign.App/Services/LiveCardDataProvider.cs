using MoldSign.Core;

namespace MoldSign.App.Services;

public sealed class LiveCardDataProvider(Func<string, Task<CertificateSummary>> read) : ICardDataProvider
{
    public async Task<CardDataResult> ReadAsync(string reader) => new(await read(reader));
}
