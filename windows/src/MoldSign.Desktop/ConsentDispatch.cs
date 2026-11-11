using MoldSign.Core;

namespace MoldSign.Desktop;

/// <summary>Worker-to-UI rendezvous. Cancellation releases the worker even if the UI queue never runs.</summary>
public sealed class ConsentDispatch(Func<Func<Task>, bool> enqueue)
{
    public ConsentResult Request(Func<CancellationToken, Task<ConsentResult>> present, CancellationToken cancellation)
    {
        if (cancellation.IsCancellationRequested) return ConsentResult.Cancelled;
        var answer = new TaskCompletionSource<ConsentResult>(TaskCreationOptions.RunContinuationsAsynchronously);
        using var registration = cancellation.Register(() => answer.TrySetResult(ConsentResult.Cancelled));
        if (!enqueue(async () =>
        {
            if (cancellation.IsCancellationRequested) return;
            try { answer.TrySetResult(await present(cancellation)); }
            catch (OperationCanceledException) { answer.TrySetResult(ConsentResult.Cancelled); }
            catch (Exception error) { answer.TrySetException(error); }
        })) return ConsentResult.Cancelled;
        return answer.Task.GetAwaiter().GetResult();
    }
}
