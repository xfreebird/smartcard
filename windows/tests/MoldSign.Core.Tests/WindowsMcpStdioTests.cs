using System.Collections.Concurrent;
using MoldSign.Cli;

namespace MoldSign.Core.Tests;

public sealed class WindowsMcpStdioTests
{
    [Fact]
    public async Task CancellationIsReadDuringWorkAndOnlySuppressesItsReply()
    {
        using var input = new ControlledInput();
        var entered = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        using var release = new ManualResetEventSlim();
        using var reply = new ManualResetEventSlim();
        var output = new ReplyWriter(reply);
        var error = new StringWriter();
        var disconnected = false;
        var calls = 0;
        var session = Task.Factory.StartNew(() => McpStdioSession.Run(input, output, error, line =>
        {
            Interlocked.Increment(ref calls);
            if (line.Contains("first", StringComparison.Ordinal)) { entered.TrySetResult(); Assert.True(release.Wait(TimeSpan.FromSeconds(5))); return "first"; }
            return "second";
        }, () => disconnected = true), CancellationToken.None, TaskCreationOptions.LongRunning, TaskScheduler.Default);
        input.Feed("{\"jsonrpc\":\"2.0\",\"id\":\"first\",\"method\":\"ping\"}\n");
        await entered.Task.WaitAsync(TimeSpan.FromSeconds(30));
        input.Feed("{\"jsonrpc\":\"2.0\",\"method\":\"notifications/cancelled\",\"params\":{\"requestId\":\"first\"}}\n");
        Assert.True(input.WaitUntilDrained());
        release.Set();
        input.Feed("{\"jsonrpc\":\"2.0\",\"id\":\"second\",\"method\":\"ping\"}\n");
        Assert.True(reply.Wait(TimeSpan.FromSeconds(5)));
        input.End();
        Assert.Equal(0, await session.WaitAsync(TimeSpan.FromSeconds(5)));
        Assert.Equal("second" + Environment.NewLine, output.ToString());
        Assert.Equal(2, calls);
        Assert.True(disconnected);
        Assert.Empty(error.ToString());
    }

    [Fact]
    public async Task EofDiscardsPendingWorkWithoutRetryingActiveOperation()
    {
        using var input = new ControlledInput();
        var entered = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        using var release = new ManualResetEventSlim();
        using var closed = new ManualResetEventSlim();
        var output = new StringWriter(); var error = new StringWriter(); var calls = 0;
        var session = Task.Factory.StartNew(() => McpStdioSession.Run(input, output, error, _ =>
        {
            Interlocked.Increment(ref calls); entered.TrySetResult(); Assert.True(release.Wait(TimeSpan.FromSeconds(5))); return "reply";
        }, () => { }, closed.Set), CancellationToken.None, TaskCreationOptions.LongRunning, TaskScheduler.Default);
        input.Feed("{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"ping\"}\n");
        await entered.Task.WaitAsync(TimeSpan.FromSeconds(30));
        input.Feed("{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"ping\"}\n");
        input.End();
        Assert.True(closed.Wait(TimeSpan.FromSeconds(5)));
        release.Set();
        Assert.Equal(0, await session.WaitAsync(TimeSpan.FromSeconds(5)));
        Assert.Equal(1, calls);
        Assert.Empty(output.ToString());
    }

    private sealed class ReplyWriter(ManualResetEventSlim reply) : StringWriter
    {
        public override void WriteLine(string? value) { base.WriteLine(value); reply.Set(); }
    }
    private sealed class ControlledInput : TextReader
    {
        private readonly BlockingCollection<int> characters = new();
        private readonly object gate = new();
        private readonly ManualResetEventSlim drained = new();
        public ManualResetEventSlim EofRead { get; } = new();
        public void Feed(string value) { lock (gate) { drained.Reset(); foreach (var c in value) characters.Add(c); } }
        public void End() => characters.Add(-1);
        public bool WaitUntilDrained() => drained.Wait(TimeSpan.FromSeconds(5));
        public override int Read()
        {
            int next;
            lock (gate)
            {
                if (characters.TryTake(out next)) return next;
                drained.Set();
            }
            next = characters.Take();
            if (next == -1) EofRead.Set();
            return next;
        }
    }
}
