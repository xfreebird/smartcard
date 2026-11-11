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
        // Request deliberately blocks a worker. A dedicated thread avoids testing thread-pool
        // availability when other integration tests also have synchronous waits.
        var worker = Task.Factory.StartNew(
            () => dispatcher.Request(_ => { presented = true; return Task.FromResult(ConsentResult.Cancelled); }, cancellation.Token),
            CancellationToken.None, TaskCreationOptions.LongRunning, TaskScheduler.Default);
        try
        {
            var delayed = await queued.Task.WaitAsync(TimeSpan.FromSeconds(10));
            cancellation.Cancel();
            var result = await worker.WaitAsync(TimeSpan.FromSeconds(3));
            Assert.True(result.IsCancelled);
            await delayed();
            Assert.False(presented);
        }
        finally
        {
            cancellation.Cancel();
        }
    }

    [Fact]
    public void RejectedDispatchNeverPresents()
    {
        var dispatcher = new ConsentDispatch(_ => false);
        var result = dispatcher.Request(_ => throw new InvalidOperationException("Must not present"), CancellationToken.None);
        Assert.True(result.IsCancelled);
    }
}
