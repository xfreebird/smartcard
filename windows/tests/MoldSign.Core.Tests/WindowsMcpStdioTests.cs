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
        // The test owns this gate; an independent handler timeout can expire while its
        // async continuation is waiting for a busy test runner. Finally always releases it.
        using var release = new ManualResetEventSlim();
        var reply = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var output = new ReplyWriter(reply);
        var error = new StringWriter();
        var disconnected = false;
        var calls = 0;
        var session = Task.Factory.StartNew(() => McpStdioSession.Run(input, output, error, line =>
        {
            Interlocked.Increment(ref calls);
            if (line.Contains("first", StringComparison.Ordinal)) { entered.TrySetResult(); release.Wait(); return "first"; }
            return "second";
        }, () => disconnected = true), CancellationToken.None, TaskCreationOptions.LongRunning, TaskScheduler.Default);
        try
        {
            input.Feed("{\"jsonrpc\":\"2.0\",\"id\":\"first\",\"method\":\"ping\"}\n");
            await entered.Task.WaitAsync(TimeSpan.FromSeconds(30));
            input.Feed("{\"jsonrpc\":\"2.0\",\"method\":\"notifications/cancelled\",\"params\":{\"requestId\":\"first\"}}\n");
            Assert.True(input.WaitUntilDrained());
            release.Set();
            input.Feed("{\"jsonrpc\":\"2.0\",\"id\":\"second\",\"method\":\"ping\"}\n");
            await reply.Task.WaitAsync(TimeSpan.FromSeconds(10));
            input.End();
            Assert.Equal(0, await session.WaitAsync(TimeSpan.FromSeconds(5)));
            Assert.Equal("second" + Environment.NewLine, output.ToString());
            Assert.Equal(2, calls);
            Assert.True(disconnected);
            Assert.Empty(error.ToString());
        }
        finally
        {
            release.Set();
            input.End();
            await session.WaitAsync(TimeSpan.FromSeconds(10));
        }
    }

    [Fact]
    public async Task EofDiscardsPendingWorkWithoutRetryingActiveOperation()
    {
        using var input = new ControlledInput();
        var entered = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        using var release = new ManualResetEventSlim();
        var closed = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var output = new StringWriter(); var error = new StringWriter(); var calls = 0;
        var session = Task.Factory.StartNew(() => McpStdioSession.Run(input, output, error, _ =>
        {
            Interlocked.Increment(ref calls); entered.TrySetResult(); release.Wait(); return "reply";
        }, () => { }, () => closed.TrySetResult()), CancellationToken.None, TaskCreationOptions.LongRunning, TaskScheduler.Default);
        try
        {
            input.Feed("{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"ping\"}\n");
            await entered.Task.WaitAsync(TimeSpan.FromSeconds(30));
            input.Feed("{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"ping\"}\n");
            input.End();
            await closed.Task.WaitAsync(TimeSpan.FromSeconds(10));
            release.Set();
            Assert.Equal(0, await session.WaitAsync(TimeSpan.FromSeconds(5)));
            Assert.Equal(1, calls);
            Assert.Empty(output.ToString());
        }
        finally
        {
            release.Set();
            input.End();
            await session.WaitAsync(TimeSpan.FromSeconds(10));
        }
    }

    private sealed class ReplyWriter(TaskCompletionSource reply) : StringWriter
    {
        public override void WriteLine(string? value) { base.WriteLine(value); reply.TrySetResult(); }
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
