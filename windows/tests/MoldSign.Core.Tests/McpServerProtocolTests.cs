using System.Text;
using System.Text.Json.Nodes;
using MoldSign.Cli;

namespace MoldSign.Core.Tests;

/// <summary>Local MCP JSON-RPC framing rules and offline XAdES verification with operator-chosen detached roots.</summary>
public sealed class McpServerProtocolTests
{
    private static JsonObject Meta(string version = McpServer.Version) => new()
    {
        ["io.modelcontextprotocol/protocolVersion"] = version,
        ["io.modelcontextprotocol/clientCapabilities"] = new JsonObject(),
    };

    private static JsonObject Request(string method, JsonObject? parameters = null, JsonNode? id = null)
    {
        parameters ??= new JsonObject();
        if (!parameters.ContainsKey("_meta")) parameters["_meta"] = Meta();
        return new JsonObject { ["jsonrpc"] = "2.0", ["id"] = id ?? 7, ["method"] = method, ["params"] = parameters };
    }

    private static JsonObject Send(McpServer server, JsonNode request) =>
        JsonNode.Parse(server.Handle(McpServer.Encode(request))!)!.AsObject();

    private static int ErrorCode(JsonObject response) => response["error"]!["code"]!.GetValue<int>();

    private static JsonObject Call(McpServer server, string name, JsonObject arguments) =>
        Send(server, Request("tools/call", new JsonObject { ["name"] = name, ["arguments"] = arguments }))["result"]!["structuredContent"]!.AsObject();

    private static readonly Dictionary<string, McpTrustedRoot> s_noRoots = new();

    [Fact]
    public void Malformed_envelopes_are_invalid_requests_without_echoing_the_id()
    {
        var server = new McpServer(s_noRoots);
        JsonNode[] invalid =
        [
            new JsonArray(),
            new JsonObject { ["jsonrpc"] = "1.0", ["id"] = 1, ["method"] = "ping" },
            new JsonObject { ["jsonrpc"] = "2.0", ["id"] = 1 },
            new JsonObject { ["jsonrpc"] = "2.0", ["id"] = new JsonObject(), ["method"] = "ping" },
            new JsonObject { ["jsonrpc"] = "2.0", ["id"] = true, ["method"] = "ping" },
            new JsonObject { ["jsonrpc"] = "2.0", ["id"] = new string('x', 129), ["method"] = "ping" },
            new JsonObject { ["jsonrpc"] = "2.0", ["id"] = 1, ["method"] = "ping", ["extra"] = 1 },
        ];
        foreach (var request in invalid)
        {
            var response = Send(server, request);
            Assert.Equal(-32600, ErrorCode(response));
            Assert.Null(response["id"]);
        }
    }

    [Fact]
    public void Requests_need_current_metadata_and_answer_ping_and_discovery()
    {
        var server = new McpServer(s_noRoots);
        var missing = Request("ping"); missing["params"]!.AsObject().Remove("_meta");
        Assert.Equal("Required request metadata is missing", Send(server, missing)["error"]!["message"]!.GetValue<string>());
        Assert.Equal(-32022, ErrorCode(Send(server, Request("ping", new JsonObject { ["_meta"] = Meta("2024-01-01") }))));
        var notObject = new JsonObject { ["jsonrpc"] = "2.0", ["id"] = 1, ["method"] = "ping", ["params"] = 5 };
        Assert.Equal(-32602, ErrorCode(Send(server, notObject)));
        var metaNotObject = new JsonObject { ["jsonrpc"] = "2.0", ["id"] = 1, ["method"] = "ping", ["params"] = new JsonObject { ["_meta"] = "x" } };
        Assert.Equal(-32602, ErrorCode(Send(server, metaNotObject)));

        var ping = Send(server, Request("ping", id: "abc"));
        Assert.Equal("abc", ping["id"]!.GetValue<string>());
        Assert.Equal("complete", ping["result"]!["resultType"]!.GetValue<string>());
        Assert.Equal("esemnbun-windows-mcp", ping["result"]!["_meta"]!["io.modelcontextprotocol/serverInfo"]!["name"]!.GetValue<string>());

        var discovery = Send(server, Request("server/discover"))["result"]!;
        Assert.Equal([McpServer.Version, McpServer.LegacyVersion], discovery["supportedVersions"]!.AsArray().Select(v => v!.GetValue<string>()));
        Assert.Equal(-32602, ErrorCode(Send(server, Request("server/discover", new JsonObject { ["unexpected"] = 1 }))));
        Assert.Equal(-32602, ErrorCode(Send(server, Request("tools/list", new JsonObject { ["cursor"] = "1" }))));
        Assert.Equal(-32601, ErrorCode(Send(server, Request("resources/list"))));
    }

    [Fact]
    public void Initialization_is_legacy_only_and_happens_once()
    {
        var server = new McpServer(s_noRoots);
        JsonObject Initialize(string version, JsonObject? client = null) => new()
        {
            ["jsonrpc"] = "2.0", ["id"] = 1, ["method"] = "initialize",
            ["params"] = new JsonObject { ["protocolVersion"] = version, ["capabilities"] = new JsonObject(),
                ["clientInfo"] = client ?? new JsonObject { ["name"] = "test", ["version"] = "1" } },
        };
        Assert.Equal(-32602, ErrorCode(Send(server, Initialize(McpServer.Version))));
        Assert.Equal(-32602, ErrorCode(Send(server, Initialize(McpServer.LegacyVersion, new JsonObject { ["name"] = "test" }))));
        Assert.Equal(McpServer.LegacyVersion, Send(server, Initialize(McpServer.LegacyVersion))["result"]!["protocolVersion"]!.GetValue<string>());
        Assert.Equal(-32602, ErrorCode(Send(server, Initialize(McpServer.LegacyVersion))));
        // After legacy initialization requests may omit metadata; the result keeps the legacy shape.
        var ping = Send(server, new JsonObject { ["jsonrpc"] = "2.0", ["id"] = 2, ["method"] = "ping" });
        Assert.Null(ping["result"]!["resultType"]);
    }

    [Theory]
    [InlineData("sign_document")]
    [InlineData("prepare_signing")]
    [InlineData("get_job")]
    [InlineData("cancel_job")]
    [InlineData("delete_everything")]
    public void Signing_and_job_tools_do_not_exist_without_operator_configuration(string tool)
    {
        var server = new McpServer(s_noRoots);
        var response = Send(server, Request("tools/call", new JsonObject { ["name"] = tool, ["arguments"] = new JsonObject() }));
        Assert.Equal("Invalid tool call", response["error"]!["message"]!.GetValue<string>());
    }

    [Fact]
    public void Tool_arguments_must_be_exact()
    {
        var server = new McpServer(s_noRoots);
        var notObject = Send(server, Request("tools/call", new JsonObject { ["name"] = "capabilities", ["arguments"] = "x" }));
        Assert.Equal(-32602, ErrorCode(notObject));
        var extra = Call(server, "capabilities", new JsonObject { ["verbose"] = true });
        Assert.False(extra["ok"]!.GetValue<bool>());
        Assert.Equal("INVALID_ARGUMENT", extra["error"]!["code"]!.GetValue<string>());
        Assert.Equal("The operation could not be completed.", extra["error"]!["message"]!.GetValue<string>());
        var unknownRoot = Call(server, "verify_document", new JsonObject { ["input"] = new JsonObject { ["rootId"] = "none", ["relativePath"] = "a.pdf" } });
        Assert.Equal("INVALID_ARGUMENT", unknownRoot["error"]!["code"]!.GetValue<string>());
    }

    [Fact]
    public void Detached_xades_is_verified_only_from_the_operator_detached_root()
    {
        using var identity = new SigningCoreTests.TestIdentity();
        using var pki = new SigningCoreTests.FakePki(identity);
        var signatures = Directory.CreateTempSubdirectory("esemnbun-mcp-xades-");
        var documents = Directory.CreateTempSubdirectory("esemnbun-mcp-docs-");
        try
        {
            var document = Path.Combine(documents.FullName, "document.txt");
            File.WriteAllText(document, "Contract de test");
            var xml = new XadesSigner(pki.Trust).Sign([document], XadesFormat.Bes, XadesPackaging.Detached,
                identity.Certificate, identity.Chain, identity.Sign, "SHA-256");
            File.WriteAllBytes(Path.Combine(signatures.FullName, "document.xml"), xml);
            var text = Encoding.UTF8.GetString(xml);
            File.WriteAllText(Path.Combine(signatures.FullName, "remote.xml"), text.Replace("file:/document.txt", "https://example.test/document.txt"));
            File.WriteAllText(Path.Combine(signatures.FullName, "escape.xml"), text.Replace("file:/document.txt", "file:/..%2Fsecret.txt"));
            File.WriteAllText(Path.Combine(signatures.FullName, "notes.txt"), "not a signature");
            File.WriteAllText(Path.Combine(signatures.FullName, "bad.pdf"), "GIF89a");
            using var signatureRoot = new McpTrustedRoot(signatures.FullName);
            using var documentRoot = new McpTrustedRoot(documents.FullName);
            var server = new McpServer(new Dictionary<string, McpTrustedRoot> { ["sig"] = signatureRoot, ["docs"] = documentRoot });
            JsonObject Verify(string path, string? detached = null)
            {
                var arguments = new JsonObject { ["input"] = new JsonObject { ["rootId"] = "sig", ["relativePath"] = path } };
                if (detached is not null) arguments["detachedRootId"] = detached;
                return Call(server, "verify_document", arguments);
            }

            var complete = Verify("document.xml", "docs")["data"]!;
            Assert.Equal("unconfirmed", complete["status"]!.GetValue<string>()); // fixture CA is not a pinned root
            Assert.Equal("offline", complete["mode"]!.GetValue<string>());
            Assert.False(complete["revocationChecked"]!.GetValue<bool>());
            var signature = Assert.Single(complete["signatures"]!.AsArray())!;
            Assert.Equal("XAdES-BES", signature["level"]!.GetValue<string>());
            Assert.True(signature["contentIntact"]!.GetValue<bool>());
            Assert.True(signature["signatureValid"]!.GetValue<bool>());
            Assert.Equal(0, signature["missingDocumentCount"]!.GetValue<int>());

            var incomplete = Verify("document.xml")["data"]!;
            Assert.Equal("incomplete", incomplete["status"]!.GetValue<string>()); // the reference was not supplied
            Assert.Equal(1, incomplete["signatures"]![0]!["missingDocumentCount"]!.GetValue<int>());

            Assert.Equal("INVALID_DOCUMENT", Verify("remote.xml", "docs")["error"]!["code"]!.GetValue<string>());
            Assert.Equal("PATH_DENIED", Verify("escape.xml", "docs")["error"]!["code"]!.GetValue<string>());
            Assert.Equal("UNSUPPORTED", Verify("notes.txt")["error"]!["code"]!.GetValue<string>());
            Assert.Equal("INVALID_DOCUMENT", Verify("bad.pdf")["error"]!["code"]!.GetValue<string>());
            Assert.Equal("INVALID_ARGUMENT", Verify("document.xml", "missing-root")["error"]!["code"]!.GetValue<string>());
            Assert.Equal(1, identity.SignCalls); // only the fixture signature; verification never signs
        }
        finally { signatures.Delete(true); documents.Delete(true); }
    }

    [Fact]
    public void Configured_signing_tools_are_listed_with_schemas_and_routed_to_their_policy()
    {
        using var identity = new SigningCoreTests.TestIdentity();
        using var pki = new SigningCoreTests.FakePki(identity);
        var directory = Directory.CreateTempSubdirectory("esemnbun-mcp-tools-");
        try
        {
            WindowsMcpApprovalTests.Private(directory);
            foreach (var child in new[] { "requests", "responses", "outputs", "signed" }) WindowsMcpApprovalTests.Private(directory.CreateSubdirectory(child));
            var documents = directory.CreateSubdirectory("docs");
            File.WriteAllBytes(Path.Combine(documents.FullName, "contract.pdf"), SigningCoreTests.MinimalPdf());
            using var broker = new WindowsMcpApprovalTransport(directory.FullName);
            using var signed = new McpTrustedRoot(Path.Combine(directory.FullName, "signed"), privateDirectory: true);
            using var docs = new McpTrustedRoot(documents.FullName);
            var service = new SigningService(() =>
            {
                var sim = IdentityGuardTests.Simulator(identity.Certificate, CosmoXCardTests.SessionAfterAuthentication());
                sim.InternalAuthenticate = identity.Sign;
                return new IdentityGuardTests.AuthenticatingTransport(sim, "MCP fixture");
            }, pki.Trust);
            var fingerprint = Convert.ToHexString(System.Security.Cryptography.SHA256.HashData(identity.Certificate));
            var unattended = new WindowsMcpUnattendedSigner(signed, fingerprint, () => "1234", service);
            var server = new McpServer(new Dictionary<string, McpTrustedRoot>
                { ["docs"] = docs, ["broker-output"] = broker.Outputs, ["unattended-output"] = signed }, unattended, broker);

            var tools = Send(server, Request("tools/list"))["result"]!["tools"]!.AsArray();
            Assert.Equal(["capabilities", "verify_document", "prepare_signing", "get_job", "cancel_job", "sign_document"],
                tools.Select(tool => tool!["name"]!.GetValue<string>()));
            var job = tools.Single(tool => tool!["name"]!.GetValue<string>() == "get_job")!;
            Assert.Equal(WindowsMcpApprovalTransport.States,
                job["outputSchema"]!["oneOf"]![0]!["properties"]!["data"]!["properties"]!["state"]!["enum"]!.AsArray().Select(v => v!.GetValue<string>()));
            Assert.False(tools.Single(tool => tool!["name"]!.GetValue<string>() == "sign_document")!["annotations"]!["readOnlyHint"]!.GetValue<bool>());

            var input = new JsonObject { ["rootId"] = "docs", ["relativePath"] = "contract.pdf" };
            var signature = Call(server, "sign_document", new JsonObject { ["input"] = input.DeepClone(), ["format"] = "PAdES-T" });
            Assert.True(signature["ok"]!.GetValue<bool>(), McpServer.Encode(signature));
            var output = signature["data"]!["output"]!;
            Assert.Equal("unattended-output", output["rootId"]!.GetValue<string>());
            Assert.Equal(1, identity.SignCalls);
            var verified = Call(server, "verify_document", new JsonObject { ["input"] = output.DeepClone() })["data"]!;
            Assert.Equal(1, verified["signatureCount"]!.GetValue<int>());
            Assert.True(verified["signatures"]![0]!["signatureValid"]!.GetValue<bool>());
            Assert.Equal("INVALID_ARGUMENT", Call(server, "sign_document", new JsonObject { ["input"] = input.DeepClone(), ["format"] = "XAdES-T" })["error"]!["code"]!.GetValue<string>());

            var prepared = Call(server, "prepare_signing", new JsonObject { ["input"] = input.DeepClone(), ["format"] = "PAdES-T" })["data"]!;
            var id = prepared["jobId"]!.GetValue<string>();
            Assert.Equal("awaiting_user", Call(server, "get_job", new JsonObject { ["jobId"] = id })["data"]!["state"]!.GetValue<string>());
            Assert.True(Call(server, "cancel_job", new JsonObject { ["jobId"] = id })["data"]!["cancellationRequested"]!.GetValue<bool>());
            Assert.Equal("INVALID_ARGUMENT", Call(server, "get_job", new JsonObject { ["jobId"] = id, ["extra"] = 1 })["error"]!["code"]!.GetValue<string>());
            Assert.Equal("UNKNOWN_JOB", Call(server, "get_job", new JsonObject { ["jobId"] = Guid.NewGuid().ToString("D") })["error"]!["code"]!.GetValue<string>());
            Assert.Equal(1, identity.SignCalls); // staging and job queries never sign
        }
        finally { directory.Delete(true); }
    }

    [Fact]
    public void Root_identifiers_are_short_ascii_tokens()
    {
        Assert.True(McpServer.Identifier("docs_2026-11"));
        Assert.False(McpServer.Identifier(""));
        Assert.False(McpServer.Identifier("doc s"));
        Assert.False(McpServer.Identifier("dosar-ă"));
        Assert.False(McpServer.Identifier(new string('a', 65)));
    }
}
