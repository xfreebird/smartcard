using System.Security.Cryptography;
using MoldSign.Cli;
using MoldSign.Core.Protection;

namespace MoldSign.Core.Tests;

/// <summary>encrypt / decrypt / encryption-certs / remove-file through the CLI with the SM card simulator.</summary>
public sealed class FileProtectionCommandTests : IDisposable
{
    private readonly DirectoryInfo _directory = Directory.CreateTempSubdirectory("esemnbun-protect-");
    private static readonly string s_fingerprint =
        Convert.ToHexString(SHA256.HashData(CardFileProtectionTests.Fixture("test-recipient.der")));

    public void Dispose() => _directory.Delete(true);

    private string PathOf(string name) => Path.Combine(_directory.FullName, name);

    private string Write(string name, byte[] bytes)
    {
        var path = PathOf(name);
        File.WriteAllBytes(path, bytes);
        return path;
    }

    [Fact]
    public void Encryption_certificates_are_listed_and_exported_without_a_pin()
    {
        var cards = new EncryptionCards();
        var listing = Run(cards, ["encryption-certs", "--reader", "Simulated"]);
        Assert.Equal(0, listing.Code);
        Assert.Equal($"{s_fingerprint}  Encryption key", listing.Out.Trim());

        var exported = PathOf("recipient.cer");
        var export = Run(cards, ["encryption-certs", "--card", s_fingerprint.ToLowerInvariant(), "--out", exported]);
        Assert.Equal(0, export.Code);
        Assert.Equal("Exported public encryption certificate.", export.Out.Trim());
        Assert.Equal(CardFileProtectionTests.Fixture("test-recipient.der"), File.ReadAllBytes(exported));
        Assert.Equal(1, Run(cards, ["encryption-certs", "--card", s_fingerprint, "--out", exported]).Code); // never overwrites

        var unknown = Run(cards, ["encryption-certs", "--card", new string('A', 64), "--out", PathOf("other.cer")]);
        Assert.Equal(1, unknown.Code);
        Assert.Equal("Selected encryption certificate not found.", unknown.Err.Trim());
        Assert.False(File.Exists(PathOf("other.cer")));
        Assert.DoesNotContain(cards.Commands, command => command[1] == 0x20);
    }

    [Fact]
    public void Card_encryption_round_trips_with_one_pin_from_stdin()
    {
        var cards = new EncryptionCards();
        byte[] plain = [0, 1, 2, 0x80, 255];
        var input = Write("contract.bin", plain);
        var encrypted = PathOf("contract.p7m");
        var encrypt = Run(cards, ["encrypt", input, encrypted, "--card", s_fingerprint]);
        Assert.Equal(0, encrypt.Code);
        Assert.Equal($"Saved: {encrypted}", encrypt.Out.Trim());
        Assert.DoesNotContain(cards.Commands, command => command[1] == 0x20); // encryption needs no PIN

        var decrypted = PathOf("contract.out");
        var decrypt = Run(cards, ["decrypt", encrypted, decrypted, "--card", s_fingerprint, "--pin-stdin"], stdin: "1234\n");
        Assert.Equal(0, decrypt.Code);
        Assert.Equal(plain, File.ReadAllBytes(decrypted));
        Assert.Contains("Check the decrypted content before using it.", decrypt.Err);
        Assert.Single(cards.Commands, command => command[1] == 0x20);
        Assert.Single(cards.Commands, command => command[1] == 0x2a);
    }

    [Fact]
    public void Card_decryption_takes_the_environment_pin_then_the_prompt()
    {
        var cards = new EncryptionCards();
        var envelope = Write("vendor.p7m", CardFileProtectionTests.Fixture("vendor-certificate.asymmetric.p7m"));
        var fromEnvironment = Run(cards, ["decrypt", envelope, PathOf("one.bin"), "--card", s_fingerprint], environmentPin: "1234");
        Assert.Equal(0, fromEnvironment.Code);
        Assert.Equal(CardFileProtectionTests.Fixture("plain-1024.bin"), File.ReadAllBytes(PathOf("one.bin")));

        string? prompt = null;
        var prompted = Run(cards, ["decrypt", envelope, PathOf("two.bin"), "--card", s_fingerprint],
            redirected: false, secret: text => { prompt = text; return "1234"; });
        Assert.Equal(0, prompted.Code);
        Assert.Equal("Card PIN: ", prompt);

        var cancelled = Run(cards, ["decrypt", envelope, PathOf("three.bin"), "--card", s_fingerprint], redirected: false);
        Assert.Equal(1, cancelled.Code);
        Assert.Equal("Card authorization cancelled.", cancelled.Err.Trim());

        var unattended = Run(cards, ["decrypt", envelope, PathOf("four.bin"), "--card", s_fingerprint]);
        Assert.Equal(1, unattended.Code);
        Assert.Equal("Use --pin-stdin for unattended input.", unattended.Err.Trim());
        Assert.False(File.Exists(PathOf("three.bin")) || File.Exists(PathOf("four.bin")));
    }

    [Fact]
    public void Wrong_pin_and_a_changed_identity_stop_before_any_output()
    {
        var envelope = Write("vendor.p7m", CardFileProtectionTests.Fixture("vendor-certificate.asymmetric.p7m"));
        var wrong = Run(new EncryptionCards { VerifyStatus = 0x63C1 },
            ["decrypt", envelope, PathOf("out.bin"), "--card", s_fingerprint, "--pin-stdin"], stdin: "9999\n");
        Assert.Equal(3, wrong.Code);

        var changed = Run(new EncryptionCards(), ["decrypt", envelope, PathOf("out.bin"), "--card", new string('B', 64), "--pin-stdin"], stdin: "1234\n");
        Assert.Equal(1, changed.Code);
        Assert.Equal("Selected encryption identity not found.", changed.Err.Trim());
        Assert.False(File.Exists(PathOf("out.bin")));
    }

    [Fact]
    public void Password_protection_round_trips_and_confirms_interactive_passwords()
    {
        var cards = new EncryptionCards();
        var input = Write("note.txt", "Notă confidențială"u8.ToArray());
        var encrypt = Run(cards, ["encrypt", input, PathOf("note.p7m"), "--password-stdin"], stdin: "parola-test\n");
        Assert.Equal(0, encrypt.Code);
        var decrypt = Run(cards, ["decrypt", PathOf("note.p7m"), PathOf("note.out"), "--password-stdin"], stdin: "parola-test\n");
        Assert.Equal(0, decrypt.Code);
        Assert.Equal(File.ReadAllBytes(input), File.ReadAllBytes(PathOf("note.out")));

        var answers = new Queue<string>(["first", "second"]);
        var mismatch = Run(cards, ["encrypt", input, PathOf("mismatch.p7m")], redirected: false, secret: _ => answers.Dequeue());
        Assert.Equal(1, mismatch.Code);
        Assert.Equal("Passwords do not match.", mismatch.Err.Trim());

        var confirmed = new Queue<string>(["same", "same"]);
        Assert.Equal(0, Run(cards, ["encrypt", input, PathOf("confirmed.p7m")], redirected: false, secret: _ => confirmed.Dequeue()).Code);

        var redirected = Run(cards, ["encrypt", input, PathOf("redirected.p7m")]);
        Assert.Equal(1, redirected.Code);
        Assert.Equal("Use --password-stdin for non-interactive input.", redirected.Err.Trim());
        Assert.Empty(cards.Connections);
    }

    [Theory]
    [InlineData("encrypt", "--out", "x.cer")]
    [InlineData("encrypt", "--card", "1234")]
    [InlineData("encrypt", "--pin", "1234")]
    [InlineData("decrypt", "--certificate", "x.der")]
    [InlineData("remove-file")]
    public void Unsupported_option_combinations_are_usage_errors(string command, params string[] options)
    {
        var input = Write("in.bin", [1]);
        var cards = new EncryptionCards();
        var result = Run(cards, [command, input, PathOf("new.bin"), .. options]);
        Assert.Equal(1, result.Code);
        Assert.False(File.Exists(PathOf("new.bin")));
        Assert.Empty(cards.Connections);
    }

    [Fact]
    public void Existing_destinations_and_removal_need_explicit_new_names_and_confirmation()
    {
        var input = Write("in.bin", [1, 2, 3]);
        var existing = Write("existing.bin", [9]);
        var exists = Run(new EncryptionCards(), ["encrypt", input, existing, "--password-stdin"], stdin: "p\n");
        Assert.Equal(1, exists.Code);
        Assert.Equal("Destination exists; choose a new filename.", exists.Err.Trim());
        Assert.Equal(new byte[] { 9 }, File.ReadAllBytes(existing));

        Assert.Equal(1, Run(new EncryptionCards(), ["remove-file", input]).Code);
        Assert.True(File.Exists(input));
        var removed = Run(new EncryptionCards(), ["remove-file", input, "--confirm-removal", "--quiet"]);
        if (!OperatingSystem.IsWindows())
        {
            // Overwrite-then-delete-by-handle is implemented for Windows only; elsewhere nothing is touched.
            Assert.Equal(1, removed.Code);
            Assert.Equal("Overwrite/removal requires Windows.", removed.Err.Trim());
            Assert.Equal(new byte[] { 1, 2, 3 }, File.ReadAllBytes(input));
            return;
        }
        Assert.True(removed.Code == 0, removed.Err);
        Assert.Equal("Removed. Other copies and physical remnants may remain.", removed.Out.Trim());
        Assert.False(File.Exists(input));
    }

    private static (int Code, string Out, string Err) Run(ICardAccess cards, string[] args, string stdin = "",
        string? environmentPin = null, bool redirected = true, Func<string, string?>? secret = null)
    {
        var output = new StringWriter();
        var error = new StringWriter();
        var host = new CliHost
        {
            Cards = cards, In = new StringReader(stdin), Out = output, Error = error,
            IsInputRedirected = () => redirected,
            GetEnvironmentVariable = name => name == "MSIGN_PIN" ? environmentPin : null,
            PromptHidden = secret ?? (_ => null),
        };
        return (CliApp.Run(args, host), output.ToString(), error.ToString());
    }

    /// <summary>Authenticated SM simulator holding the encryption key directory, its certificate and an RSA decipher key.</summary>
    private sealed class EncryptionCards : ICardAccess
    {
        public ushort VerifyStatus { get; init; } = 0x9000;
        public List<string?> Connections { get; } = [];
        public List<byte[]> Commands { get; } = [];

        public IReadOnlyList<SmartCardReaderInfo> ListReaders() => [new("Simulated", true)];

        public ICardTransport Connect(string? readerName)
        {
            Connections.Add(readerName);
            var session = CosmoXCardTests.SessionAfterAuthentication();
            var sim = new CosmoXCardTests.SimulatedSmCard(session.SessEnc, session.SessMac, session.Ssc) { VerifyStatus = VerifyStatus };
            var metadata = CardFileProtectionTests.Metadata(pinType: 2);
            sim.ExtraFiles.Add(0x7001, metadata.Pin);
            sim.ExtraFiles.Add(0x7002, metadata.Key);
            sim.ExtraFiles.Add(0x7005, metadata.Cert);
            sim.ExtraFiles.Add(2, CardFileProtectionTests.Fixture("test-recipient.der"));
            sim.Decipher = wrapped =>
            {
                using var rsa = RSA.Create();
                rsa.ImportPkcs8PrivateKey(CardFileProtectionTests.Fixture("test-private-key.pk8"), out _);
                return rsa.Decrypt(wrapped, RSAEncryptionPadding.Pkcs1);
            };
            return new RecordingTransport(new IdentityGuardTests.AuthenticatingTransport(sim, readerName ?? "Simulated"), sim, Commands);
        }
    }

    private sealed class RecordingTransport(ICardTransport inner, CosmoXCardTests.SimulatedSmCard sim, List<byte[]> commands) : ICardTransport
    {
        public string ReaderName => inner.ReaderName;
        public byte[] Transmit(byte[] apdu) => inner.Transmit(apdu);
        public void Dispose()
        {
            commands.AddRange(sim.Commands);
            inner.Dispose();
        }
    }
}
