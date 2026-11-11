using MoldSign.Core;
using MoldSign.Desktop;

namespace MoldSign.Core.Tests;

public sealed class ConsentDispatchTests
{
    [Fact]
    public async Task CancellationReleasesWorkerWhenUiNeverRuns()
    {
        using var cancellation = new CancellationTokenSource();
        var queued = new TaskCompletionSource<Func<Task>>(TaskCreationOptions.RunContinuationsAsynchronously);
        var dispatcher = new ConsentDispatch(action => { queued.SetResult(action); return true; });
        var presented = false;
        var worker = Task.Run(() => dispatcher.Request(_ => { presented = true; return Task.FromResult(ConsentResult.Cancelled); }, cancellation.Token));
        var delayed = await queued.Task.WaitAsync(TimeSpan.FromSeconds(3));
        cancellation.Cancel();
        var result = await worker.WaitAsync(TimeSpan.FromSeconds(3));
        Assert.True(result.IsCancelled);
        await delayed();
        Assert.False(presented);
    }

    [Fact]
    public void RejectedDispatchNeverPresents()
    {
        var dispatcher = new ConsentDispatch(_ => false);
        var result = dispatcher.Request(_ => throw new InvalidOperationException("Must not present"), CancellationToken.None);
        Assert.True(result.IsCancelled);
    }
}
