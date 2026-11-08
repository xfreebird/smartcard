using System.Diagnostics;
using System.Text;
using System.Text.Json.Nodes;

namespace MoldSign.Cli;

/// <summary>Bounded reader and serial executor. Cancellation suppresses replies, never retries or rolls back signing.</summary>
internal static class McpStdioSession
{
    private sealed class Frame(string line, string? id, bool signing)
    {
        public string Line { get; } = line;
        public string? Id { get; } = id;
        public bool Signing { get; } = signing;
        public bool Cancelled { get; set; }
    }
    internal static int Run(TextReader input, TextWriter output, TextWriter error, Func<string, string?> handle, Action disconnect, Action? inputClosed = null, Action<int>? terminate = null)
    {
        var gate = new object();
        var queue = new Queue<Frame>();
        Frame? active = null;
        var eof = false;
        var stopped = false;
        string? failure = null;
        string? Id(JsonNode? node) => node is JsonValue value &&
            (value.TryGetValue<string>(out var text) && text.Length <= 128 || value.TryGetValue<long>(out _)) ? node.ToJsonString() : null;
        void Read()
        {
            var frame = new StringBuilder();
            try
            {
                while (true)
                {
                    var next = input.Read();
                    lock (gate) { if (stopped) return; }
                    if (next == -1)
                    {
                        lock (gate) { if (frame.Length > 0) failure = "Incomplete MCP frame"; eof = true; Monitor.PulseAll(gate); }
                        inputClosed?.Invoke();
                        return;
                    }
                    if (next != '\n')
                    {
                        if (frame.Length >= McpServer.MaxFrame) throw new InvalidDataException("MCP frame exceeds limit");
                        frame.Append((char)next); continue;
                    }
                    var line = frame.ToString().TrimEnd('\r'); frame.Clear();
                    if (Encoding.UTF8.GetByteCount(line) > McpServer.MaxFrame) throw new InvalidDataException("MCP frame exceeds limit");
                    JsonObject? request = null;
                    try { request = JsonNode.Parse(line, documentOptions: new() { MaxDepth = 48 }) as JsonObject; } catch { }
                    lock (gate)
                    {
                        if (stopped) return;
                        if (request?["jsonrpc"]?.ToString() == "2.0" && !request.ContainsKey("id") && request["method"]?.ToString() == "notifications/cancelled")
                        {
                            var id = Id((request["params"] as JsonObject)?["requestId"]);
                            if (id is not null)
                            {
                                if (active?.Id == id) active.Cancelled = true;
                                foreach (var pending in queue) if (pending.Id == id) pending.Cancelled = true;
                            }
                            continue;
                        }
                        // Other notifications are ignored, and cannot occupy/exhaust the execution queue.
                        if (request?["jsonrpc"]?.ToString() == "2.0" && !request.ContainsKey("id")) continue;
                        if (queue.Count + (active is null ? 0 : 1) >= 8) throw new InvalidDataException("MCP request queue exceeds limit");
                        var parameters = request?["params"] as JsonObject;
                        queue.Enqueue(new Frame(line, Id(request?["id"]), request?["method"]?.ToString() == "tools/call" && parameters?["name"]?.ToString() == "sign_document"));
                        Monitor.PulseAll(gate);
                    }
                }
            }
            catch (Exception exception)
            {
                lock (gate)
                {
                    failure = exception is InvalidDataException ? exception.Message : "MCP transport failed";
                    eof = true; Monitor.PulseAll(gate);
                }
            }
        }
        new Thread(Read) { IsBackground = true, Name = "MCP input" }.Start();
        try
        {
            while (true)
            {
                Frame work;
                lock (gate)
                {
                    while (queue.Count == 0 && !eof) Monitor.Wait(gate);
                    if (eof) break; // EOF discards queued work; the active operation has already finished.
                    work = queue.Dequeue();
                    if (work.Cancelled) continue;
                    active = work;
                }
                var operation = Task.Run(() => handle(work.Line));
                var timer = Stopwatch.StartNew();
                while (!operation.Wait(25))
                {
                    if (timer.Elapsed > TimeSpan.FromSeconds(work.Signing ? 120 : 30))
                    {
                        lock (gate) { failure = "MCP operation exceeded deadline"; stopped = true; }
                        error.WriteLine(failure); error.Flush();
                        // A live signing task must never outlive/dispose its trusted roots. In production
                        // terminate the entire process; an injected test terminator may return, in which
                        // case retain all resources until the operation has actually stopped.
                        (terminate ?? Environment.Exit)(1);
                        try { operation.GetAwaiter().GetResult(); } catch { }
                        return 1;
                    }
                }
                lock (gate)
                {
                    if (!work.Cancelled && !eof && operation.Result is { } reply) { output.WriteLine(reply); output.Flush(); }
                    active = null;
                }
            }
            return Finish();
        }
        finally
        {
            lock (gate) { stopped = true; queue.Clear(); }
            disconnect();
        }
        int Finish()
        {
            if (failure is null) return 0;
            error.WriteLine(failure); return 1;
        }
    }
}
