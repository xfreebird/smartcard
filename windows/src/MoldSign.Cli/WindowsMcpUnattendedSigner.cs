using System.Security.Cryptography;
using System.Text;
using System.Text.Json.Nodes;
using MoldSign.Core;

namespace MoldSign.Cli;

/// <summary>Explicit operator policy for local unattended PDF signing. No model-selected
/// credential, certificate or destination. Failed attempts remain blocked across restarts.</summary>
internal sealed class WindowsMcpUnattendedSigner
{
    internal const string MarkerName = ".unattended-signing-lock";
    private readonly McpTrustedRoot output;
    private readonly byte[] certificateHash;
    private readonly Func<string> credential;
    private readonly SigningService service;
    private readonly Func<string?>? selectReader;
    private readonly object operationLock = new();
    public bool Available => true;

    internal WindowsMcpUnattendedSigner(McpTrustedRoot output, string certificateSha256,
                                        Func<string> credential, SigningService service, Func<string?>? selectReader = null)
    {
        this.output = output;
        if (certificateSha256.Length != 64 || !certificateSha256.All(char.IsAsciiHexDigit))
            throw new McpException("INVALID_ARGUMENT");
        certificateHash = Convert.FromHexString(certificateSha256);
        this.credential = credential;
        this.service = service;
        this.selectReader = selectReader;
    }

    public static WindowsMcpUnattendedSigner? Create(List<string> arguments, Dictionary<string, McpTrustedRoot> roots)
    {
        string[] options = ["--signing-certificate-sha256", "--signing-output-directory", "--pin-source", "--onepassword-executable"];
        if (!arguments.Contains("--allow-unattended-signing"))
        {
            if (arguments.Any(options.Contains)) throw new McpException("INVALID_ARGUMENT");
            return null;
        }
        if (arguments.Count(a => a == "--allow-unattended-signing") != 1) throw new McpException("INVALID_ARGUMENT");
        arguments.Remove("--allow-unattended-signing");
        string? Take(string name)
        {
            var index = arguments.IndexOf(name);
            if (index < 0) return null;
            if (arguments.Count(a => a == name) != 1 || index + 1 >= arguments.Count || arguments[index + 1].StartsWith("--", StringComparison.Ordinal))
                throw new McpException("INVALID_ARGUMENT");
            var value = arguments[index + 1]; arguments.RemoveRange(index, 2); return value;
        }
        var certificate = Take("--signing-certificate-sha256") ?? throw new McpException("INVALID_ARGUMENT");
        if (certificate.Length != 64 || !certificate.All(char.IsAsciiHexDigit)) throw new McpException("INVALID_ARGUMENT");
        var outputPath = Take("--signing-output-directory") ?? throw new McpException("INVALID_ARGUMENT");
        var source = Take("--pin-source") ?? throw new McpException("INVALID_ARGUMENT");
        var executable = Take("--onepassword-executable");
        if (executable is not null && !source.StartsWith("onepassword:", StringComparison.Ordinal)) throw new McpException("INVALID_ARGUMENT");
        var pin = WindowsMcpCredentialSource.Create(source, executable);
        if (!OperatingSystem.IsWindows()) throw new McpException("UNSUPPORTED");
        var destination = new McpTrustedRoot(outputPath, privateDirectory: true);
        try
        {
            if (!roots.TryAdd("unattended-output", destination)) throw new McpException("INVALID_ARGUMENT");
            var signing = new SigningService(reader =>
            {
                if (!OperatingSystem.IsWindows()) throw new McpException("UNSUPPORTED");
                return WinSCardTransport.Connect(new WinSCardOptions { Exclusive = true, ReaderName = reader });
            });
            string SelectReader()
            {
                if (!OperatingSystem.IsWindows()) throw new McpException("UNSUPPORTED");
                var expected = Convert.FromHexString(certificate);
                var readable = false;
                foreach (var reader in WinSCardTransport.ListReaders())
                {
                    try
                    {
                        var candidate = signing.Certificate(reader); readable = true;
                        if (CryptographicOperations.FixedTimeEquals(expected, SHA256.HashData(candidate.Der))) return reader;
                    }
                    catch (CardException) { }
                }
                throw new McpException(readable ? "CARD_CHANGED" : "NO_CARD");
            }
            return new WindowsMcpUnattendedSigner(destination, certificate, pin, signing, SelectReader);
        }
        catch { destination.Dispose(); throw; }
    }

    public JsonObject Sign(byte[] pdf)
    {
        if (pdf.Length > 8 * 1024 * 1024) throw new McpException("LIMIT_EXCEEDED");
        if (!pdf.AsSpan().StartsWith("%PDF-"u8)) throw new McpException("UNSUPPORTED");
        // Snapshot caller memory before hashing or reader work.
        var input = (byte[])pdf.Clone();
        lock (operationLock)
        {
            var token = Encoding.ASCII.GetBytes(Guid.NewGuid().ToString("D"));
            try { output.WriteExclusive(MarkerName, token); }
            catch { throw new McpException("SIGNING_DISABLED"); }
            try
            {
                var reader = selectReader?.Invoke();
                var signed = service.SignPdfBytes(input, request =>
                {
                    var actual = SHA256.HashData(request.Certificate.Der);
                    if (!CryptographicOperations.FixedTimeEquals(certificateHash, actual)) throw new McpException("CARD_CHANGED");
                    var pin = credential();
                    // Defensive even for injected providers; never let malformed input reach VERIFY.
                    if (pin.Length is < 4 or > 8 || !pin.All(char.IsAsciiDigit)) throw new McpException("CREDENTIAL_UNAVAILABLE");
                    return ConsentResult.WithPin(pin);
                }, reader: reader);
                var filename = Guid.NewGuid().ToString("D") + ".pdf";
                output.WriteExclusive(filename, signed);
                if (!output.Read(MarkerName, 128).AsSpan().SequenceEqual(token)) throw new McpException("OUTCOME_UNKNOWN");
                output.Remove(MarkerName);
                return new JsonObject
                {
                    ["state"] = "completed", ["inputSHA256"] = Convert.ToHexStringLower(SHA256.HashData(input)),
                    ["outputSHA256"] = Convert.ToHexStringLower(SHA256.HashData(signed)),
                    ["output"] = new JsonObject { ["rootId"] = "unattended-output", ["relativePath"] = filename }
                };
            }
            catch (McpException) { throw; }
            catch (CardException failure)
            {
                throw new McpException(failure.Kind switch
                {
                    CardErrorKind.WrongPin => "PIN_INCORRECT", CardErrorKind.PinBlocked => "PIN_BLOCKED",
                    CardErrorKind.NoReader or CardErrorKind.NoCard => "NO_CARD",
                    CardErrorKind.CardChanged => "CARD_CHANGED", CardErrorKind.Network => "NETWORK_FAILED",
                    CardErrorKind.Format => "UNSUPPORTED", _ => "OUTCOME_UNKNOWN"
                });
            }
            catch { throw new McpException("OUTCOME_UNKNOWN"); }
        }
    }
}
