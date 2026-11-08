using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Xml;
using MoldSign.Core;

namespace MoldSign.Cli;

internal sealed class McpServer(IReadOnlyDictionary<string, McpTrustedRoot> roots, WindowsMcpUnattendedSigner? unattended = null, WindowsMcpApprovalTransport? broker = null)
{
    internal const string Version = "2026-07-28", LegacyVersion = "2025-11-25";
    internal const int MaxFrame = 65536, MaxDocument = 8 * 1024 * 1024;
    private bool initialized;
    private static JsonArray Strings(IEnumerable<string> values) => new(values.Select(x => (JsonNode?)JsonValue.Create(x)).ToArray());
    private static bool Keys(JsonObject value, string[] required, params string[] optional) =>
        required.All(value.ContainsKey) && value.All(p => required.Contains(p.Key) || optional.Contains(p.Key));
    private static string? Text(JsonObject value, string key) => value[key] is JsonValue v && v.TryGetValue<string>(out var text) ? text : null;
    internal static bool Identifier(string value) => value.Length is > 0 and <= 64 && value.All(c => char.IsAsciiLetterOrDigit(c) || c is '-' or '_');
    internal static string Encode(JsonNode node)
    {
        using var buffer = new MemoryStream();
        using (var writer = new Utf8JsonWriter(buffer)) node.WriteTo(writer);
        return Encoding.UTF8.GetString(buffer.ToArray());
    }

    internal string? Handle(string line)
    {
        JsonNode? parsed;
        try { parsed = JsonNode.Parse(line, documentOptions: new JsonDocumentOptions { MaxDepth = 48 }); }
        catch { return Encode(Error(null, -32700, "Parse error")); }
        if (parsed is not JsonObject request || Text(request, "jsonrpc") != "2.0" || Text(request, "method") is not { } method)
            return Encode(Error(null, -32600, "Invalid request"));
        if (!request.ContainsKey("id")) return null; // Notifications cannot execute operations.
        var id = request["id"];
        if (id is not JsonValue identifier || !(identifier.TryGetValue<string>(out var sid) && sid.Length <= 128 || identifier.TryGetValue<long>(out _)) ||
            !Keys(request, ["jsonrpc", "id", "method"], "params")) return Encode(Error(null, -32600, "Invalid request"));
        var parameters = request["params"] as JsonObject ?? new JsonObject();
        if (method == "initialize")
        {
            if (initialized || !Keys(parameters, ["protocolVersion", "capabilities", "clientInfo"], "_meta") ||
                Text(parameters, "protocolVersion") != LegacyVersion || parameters["capabilities"] is not JsonObject ||
                parameters["clientInfo"] is not JsonObject client || Text(client, "name") is null || Text(client, "version") is null)
                return Encode(Error(id, -32602, "Unsupported initialization"));
            initialized = true;
            return Encode(Response(id, new JsonObject { ["protocolVersion"] = LegacyVersion, ["capabilities"] = new JsonObject { ["tools"] = new JsonObject() }, ["serverInfo"] = ServerInfo() }));
        }
        var meta = parameters["_meta"] as JsonObject;
        var legacy = initialized && (meta is null || Text(meta, "io.modelcontextprotocol/protocolVersion") is null);
        if (request["params"] is not null and not JsonObject || parameters["_meta"] is not null and not JsonObject)
            return Encode(Error(id, -32602, "Invalid params"));
        if (!legacy && (meta is null || Text(meta, "io.modelcontextprotocol/protocolVersion") is null || meta["io.modelcontextprotocol/clientCapabilities"] is not JsonObject))
            return Encode(Error(id, -32602, "Required request metadata is missing"));
        if (!legacy && Text(meta!, "io.modelcontextprotocol/protocolVersion") != Version)
            return Encode(Error(id, -32022, "Unsupported protocol version"));
        JsonObject Result(JsonObject result)
        {
            if (!legacy) { result["resultType"] = "complete"; result["_meta"] = new JsonObject { ["io.modelcontextprotocol/serverInfo"] = ServerInfo() }; }
            return Response(id, result);
        }
        switch (method)
        {
            case "ping": return Encode(Result(new JsonObject()));
            case "server/discover":
                if (!Keys(parameters, [], "_meta")) return Encode(Error(id, -32602, "Invalid params"));
                return Encode(Result(new JsonObject { ["supportedVersions"] = Strings([Version, LegacyVersion]), ["capabilities"] = new JsonObject { ["tools"] = new JsonObject() } }));
            case "tools/list":
                if (!Keys(parameters, [], "_meta")) return Encode(Error(id, -32602, "Invalid params"));
                return Encode(Result(new JsonObject { ["tools"] = Tools() }));
            case "tools/call":
                if (!Keys(parameters, ["name", "arguments"], "_meta") || Text(parameters, "name") is not { } name ||
                    (name is not ("capabilities" or "verify_document") && !(name == "sign_document" && unattended is not null) && !(broker is not null && name is ("prepare_signing" or "get_job" or "cancel_job"))) || parameters["arguments"] is not JsonObject arguments)
                    return Encode(Error(id, -32602, "Invalid tool call"));
                JsonObject envelope;
                try { envelope = new JsonObject { ["schemaVersion"] = 1, ["ok"] = true, ["data"] = Call(name, arguments) }; }
                catch (Exception e)
                {
                    envelope = new JsonObject { ["schemaVersion"] = 1, ["ok"] = false,
                        ["error"] = new JsonObject { ["code"] = e is McpException failure ? failure.Code : "INVALID_DOCUMENT", ["retryable"] = false, ["message"] = "The operation could not be completed." } };
                }
                return Encode(Result(new JsonObject { ["structuredContent"] = envelope, ["content"] = new JsonArray(new JsonObject { ["type"] = "text", ["text"] = Encode(envelope) }), ["isError"] = envelope["ok"]!.GetValue<bool>() != true }));
            default: return Encode(Error(id, -32601, "Method not found"));
        }
    }

    private JsonObject Call(string name, JsonObject arguments)
    {
        if (name == "capabilities")
        {
            if (!Keys(arguments, [])) throw new McpException("INVALID_ARGUMENT");
            return new JsonObject { ["product"] = "eSemnBun", ["protocolVersion"] = Version,
                ["rootIds"] = Strings(roots.Keys.Order(StringComparer.Ordinal)), ["verificationFormats"] = Strings(["PDF", "XAdES"]),
                ["desktopApprovalBrokerAvailable"] = broker is not null, ["signingFormat"] = "PAdES-T", ["unattendedSigningAvailable"] = unattended?.Available ?? false };
        }
        if (name is "get_job" or "cancel_job")
        {
            if (!Keys(arguments, ["jobId"]) || Text(arguments, "jobId") is not { } id) throw new McpException("INVALID_ARGUMENT");
            return broker!.Job(id, name == "cancel_job");
        }
        var signing = name is "sign_document" or "prepare_signing";
        if (!(signing ? Keys(arguments, ["input", "format"]) && Text(arguments, "format") == "PAdES-T" : Keys(arguments, ["input"], "detachedRootId")) || arguments["input"] is not JsonObject input ||
            !Keys(input, ["rootId", "relativePath"]) || Text(input, "rootId") is not { } rootId ||
            !roots.TryGetValue(rootId, out var root) || Text(input, "relativePath") is not { } path)
            throw new McpException("INVALID_ARGUMENT");
        McpTrustedRoot? detached = null;
        if (arguments.ContainsKey("detachedRootId") && (Text(arguments, "detachedRootId") is not { } detachedId || !roots.TryGetValue(detachedId, out detached)))
            throw new McpException("INVALID_ARGUMENT");
        var bytes = root.Read(path, MaxDocument);
        if (name == "prepare_signing") return broker!.Prepare(bytes, Path.GetFileName(path));
        if (signing)
        {
            if (unattended is null) throw new McpException("UNSUPPORTED");
            return unattended.Sign(bytes);
        }
        IReadOnlyList<VerificationReport> reports;
        var missing = 0;
        var validator = new Validator();
        switch (Path.GetExtension(path).ToLowerInvariant())
        {
            case ".pdf":
                if (!bytes.AsSpan().StartsWith("%PDF-"u8)) throw new McpException("INVALID_DOCUMENT");
                reports = validator.ValidatePdf(bytes);
                break;
            case ".xml":
                var xml = new UTF8Encoding(false, true).GetString(bytes);
                if (xml.Contains("<!DOCTYPE", StringComparison.OrdinalIgnoreCase) || xml.Contains("<!ENTITY", StringComparison.OrdinalIgnoreCase))
                    throw new McpException("INVALID_DOCUMENT");
                var document = new XmlDocument { XmlResolver = null };
                using (var reader = XmlReader.Create(new StringReader(xml), new XmlReaderSettings { DtdProcessing = DtdProcessing.Prohibit, XmlResolver = null, MaxCharactersInDocument = MaxDocument })) document.Load(reader);
                var references = document.GetElementsByTagName("Reference", "http://www.w3.org/2000/09/xmldsig#").OfType<XmlElement>()
                    .Select(e => e.GetAttribute("URI")).Where(uri => !uri.StartsWith('#')).Distinct(StringComparer.Ordinal).ToArray();
                if (references.Length > 32) throw new McpException("LIMIT_EXCEEDED");
                var originals = new Dictionary<string, byte[]>(StringComparer.Ordinal);
                var remaining = MaxDocument - bytes.Length;
                foreach (var reference in references)
                {
                    if (!reference.StartsWith("file:/", StringComparison.Ordinal)) throw new McpException("INVALID_DOCUMENT");
                    var relative = Uri.UnescapeDataString(reference[6..]);
                    // No basename fallback: reject references escaping or changing the explicit root.
                    if (relative.Contains('/') || relative.Contains('\\') || relative.Contains(':') || relative is "." or ".." || relative.Length == 0)
                        throw new McpException("PATH_DENIED");
                    if (detached is null) { missing++; continue; }
                    var original = detached.Read(relative, remaining);
                    remaining -= original.Length;
                    originals.Add(relative, original);
                }
                reports = validator.ValidateXades(bytes, originals);
                break;
            default: throw new McpException("UNSUPPORTED");
        }
        if (reports.Count > 64) throw new McpException("LIMIT_EXCEEDED");
        var status = reports.Count == 0 ? "no_recognized_signature" : reports.Any(r => !r.SignatureValid || r.TimestampImprintValid == false) ? "invalid" :
            missing > 0 ? "incomplete" : reports.Any(r => r.Verdict == Verdict.Invalid) ? "invalid" : reports.All(r => r.Verdict == Verdict.Valid) ? "valid" : "unconfirmed";
        var signatures = new JsonArray();
        for (var i = 0; i < reports.Count; i++)
        {
            var report = reports[i];
            signatures.Add((JsonNode)new JsonObject { ["index"] = i + 1, ["kind"] = report.Kind, ["level"] = report.Level,
                ["contentIntact"] = report.ContentIntact, ["signatureValid"] = report.SignatureValid,
                ["chainTrusted"] = report.ChainTrusted, ["missingDocumentCount"] = missing });
        }
        return new JsonObject { ["status"] = status, ["mode"] = "offline", ["revocationChecked"] = false,
            ["signatureCount"] = reports.Count, ["signatures"] = signatures };
    }

    private static JsonObject ServerInfo() => new() { ["name"] = "esemnbun-windows-mcp", ["version"] = "1" };
    private static JsonObject Response(JsonNode? id, JsonObject value) => new() { ["jsonrpc"] = "2.0", ["id"] = id?.DeepClone(), ["result"] = value };
    private static JsonObject Error(JsonNode? id, int code, string message) => new() { ["jsonrpc"] = "2.0", ["id"] = id?.DeepClone(), ["error"] = new JsonObject { ["code"] = code, ["message"] = message } };
    private static JsonObject ObjectSchema(JsonObject properties, params string[] required) => new() { ["type"] = "object", ["properties"] = properties, ["required"] = Strings(required), ["additionalProperties"] = false };
    private static JsonObject StringSchema(int maximum) => new() { ["type"] = "string", ["minLength"] = 1, ["maxLength"] = maximum };
    private JsonArray Tools()
    {
        var reference = ObjectSchema(new JsonObject { ["rootId"] = StringSchema(64), ["relativePath"] = StringSchema(1024) }, "rootId", "relativePath");
        JsonObject OutputSchema(string name)
        {
            JsonObject data;
            if (name == "capabilities") data = ObjectSchema(new JsonObject {
                ["product"] = new JsonObject { ["const"] = "eSemnBun" }, ["protocolVersion"] = StringSchema(32),
                ["rootIds"] = new JsonObject { ["type"] = "array", ["maxItems"] = 32, ["items"] = StringSchema(64) },
                ["verificationFormats"] = new JsonObject { ["type"] = "array", ["items"] = StringSchema(16) },
                ["desktopApprovalBrokerAvailable"] = new JsonObject { ["type"] = "boolean" },
                ["signingFormat"] = new JsonObject { ["const"] = "PAdES-T" },
                ["unattendedSigningAvailable"] = new JsonObject { ["type"] = "boolean" } },
                "product", "protocolVersion", "rootIds", "verificationFormats", "desktopApprovalBrokerAvailable", "signingFormat", "unattendedSigningAvailable");
            else if (name is "prepare_signing" or "get_job" or "cancel_job") data = ObjectSchema(new JsonObject {
                ["jobId"] = StringSchema(36), ["state"] = new JsonObject { ["enum"] = Strings(WindowsMcpApprovalTransport.States) },
                ["cancellationRequested"] = new JsonObject { ["type"] = "boolean" },
                ["inputSHA256"] = StringSchema(64), ["outputSHA256"] = StringSchema(64),
                ["errorCode"] = new JsonObject { ["enum"] = Strings(WindowsMcpApprovalTransport.ErrorCodes) }, ["output"] = reference.DeepClone() }, "jobId", "state");
            else if (name == "sign_document") data = ObjectSchema(new JsonObject {
                ["state"] = new JsonObject { ["const"] = "completed" }, ["inputSHA256"] = StringSchema(64),
                ["outputSHA256"] = StringSchema(64), ["output"] = reference.DeepClone() }, "state", "inputSHA256", "outputSHA256", "output");
            else data = ObjectSchema(new JsonObject {
                ["status"] = new JsonObject { ["enum"] = Strings(["valid", "unconfirmed", "invalid", "incomplete", "no_recognized_signature"]) },
                ["mode"] = new JsonObject { ["const"] = "offline" }, ["revocationChecked"] = new JsonObject { ["const"] = false },
                ["signatureCount"] = new JsonObject { ["type"] = "integer" },
                ["signatures"] = new JsonObject { ["type"] = "array", ["maxItems"] = 64, ["items"] = ObjectSchema(new JsonObject {
                    ["index"] = new JsonObject { ["type"] = "integer" }, ["kind"] = StringSchema(32), ["level"] = new JsonObject { ["type"] = "string", ["maxLength"] = 64 },
                    ["contentIntact"] = new JsonObject { ["type"] = "boolean" }, ["signatureValid"] = new JsonObject { ["type"] = "boolean" },
                    ["chainTrusted"] = new JsonObject { ["type"] = "boolean" }, ["missingDocumentCount"] = new JsonObject { ["type"] = "integer" } },
                    "index", "kind", "level", "contentIntact", "signatureValid", "chainTrusted", "missingDocumentCount") } },
                "status", "mode", "revocationChecked", "signatureCount", "signatures");
            return new JsonObject { ["type"] = "object", ["oneOf"] = new JsonArray(
                ObjectSchema(new JsonObject { ["schemaVersion"] = new JsonObject { ["const"] = 1 }, ["ok"] = new JsonObject { ["const"] = true }, ["data"] = data }, "schemaVersion", "ok", "data"),
                ObjectSchema(new JsonObject { ["schemaVersion"] = new JsonObject { ["const"] = 1 }, ["ok"] = new JsonObject { ["const"] = false },
                    ["error"] = ObjectSchema(new JsonObject { ["code"] = StringSchema(64), ["message"] = StringSchema(128), ["retryable"] = new JsonObject { ["const"] = false } }, "code", "message", "retryable") }, "schemaVersion", "ok", "error")) };
        }
        JsonObject Tool(string name, string description, JsonObject schema) => new() { ["name"] = name, ["description"] = description, ["inputSchema"] = schema,
            ["outputSchema"] = OutputSchema(name), ["annotations"] = new JsonObject { ["readOnlyHint"] = true, ["destructiveHint"] = false, ["openWorldHint"] = false } };
        var tools = new JsonArray(Tool("capabilities", "Discover configured root IDs; no card or credential access.", ObjectSchema(new JsonObject())),
            Tool("verify_document", "Offline PDF/XAdES verification. No revocation check; no document text or identity is returned.",
                ObjectSchema(new JsonObject { ["input"] = reference, ["detachedRootId"] = StringSchema(64) }, "input")));
        if (broker is not null)
        {
            var prepare = Tool("prepare_signing", "Stage a PDF for foreground approval in eSemnBun. Never pass a PIN.",
                ObjectSchema(new JsonObject { ["input"] = reference.DeepClone(), ["format"] = new JsonObject { ["const"] = "PAdES-T" } }, "input", "format"));
            prepare["annotations"]!["readOnlyHint"] = false;
            prepare["annotations"]!["openWorldHint"] = true;
            tools.Add((JsonNode)prepare);
            tools.Add((JsonNode)Tool("get_job", "Read the state of a job created by this helper.", ObjectSchema(new JsonObject { ["jobId"] = StringSchema(36) }, "jobId")));
            var cancel = Tool("cancel_job", "Request cancellation. An in-progress signature cannot be undone.", ObjectSchema(new JsonObject { ["jobId"] = StringSchema(36) }, "jobId"));
            cancel["annotations"]!["readOnlyHint"] = false;
            tools.Add((JsonNode)cancel);
        }
        if (unattended is not null)
        {
            var tool = Tool("sign_document", "Sign using explicitly configured unattended policy. Never pass a PIN.",
                ObjectSchema(new JsonObject { ["input"] = reference.DeepClone(), ["format"] = new JsonObject { ["const"] = "PAdES-T" } }, "input", "format"));
            tool["annotations"] = new JsonObject { ["readOnlyHint"] = false, ["destructiveHint"] = false, ["openWorldHint"] = true };
            tools.Add((JsonNode)tool);
        }
        return tools;
    }
}
