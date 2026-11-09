using MoldSign.Core.Protection;

namespace MoldSign.Core.Tests;

public sealed class PasswordFileProtectionTests
{
    private static string Fixtures
    {
        get
        {
            var path = new DirectoryInfo(AppContext.BaseDirectory);
            while (path != null)
            {
                var candidate = Path.Combine(path.FullName, "spec", "vectors", "encryption");
                if (Directory.Exists(candidate)) return candidate;
                path = path.Parent;
            }
            throw new DirectoryNotFoundException("Encryption fixtures not found");
        }
    }
    [Fact]
    public void Reads_vendor_files_and_round_trips()
    {
        foreach (var length in new[] {0,1,15,16,17,1024})
        {
            var plain = File.ReadAllBytes(Path.Combine(Fixtures, $"plain-{length}.bin"));
            foreach(var bits in new[] {128,192,256})
                Assert.Equal(plain, PasswordFileProtection.Decrypt(File.ReadAllBytes(Path.Combine(Fixtures,$"vendor-{bits}-{length}.symmetric.p7m")), "Test-șț-🔐-2026"));
            var encrypted = PasswordFileProtection.Encrypt(plain,"Test-șț-🔐-2026");
            Assert.Equal(plain, PasswordFileProtection.Decrypt(encrypted,"Test-șț-🔐-2026"));
            var export = Environment.GetEnvironmentVariable("MSIGN_ENCRYPTION_ORACLE_OUTPUT");
            if (export != null) File.WriteAllBytes(Path.Combine(export,$"native-{length}.symmetric.p7m"),encrypted);
        }
    }
    [Fact]
    public void Legacy_vendor_files() {
        foreach(var algorithm in new[]{"3_KeyTripleDES_CBC","DES_CBC","RC2_CBC"}) foreach(var length in new[]{0,1,15,16,17,1024})
            Assert.Equal(File.ReadAllBytes(Path.Combine(Fixtures,$"plain-{length}.bin")), PasswordFileProtection.Decrypt(File.ReadAllBytes(Path.Combine(Fixtures,$"vendor-legacy-{algorithm}-{length}.p7m")),"Legacy-Test-2026"));
    }
    [Fact]
    public void Rejects_invalid_format_before_decrypting()
    {
        var envelope = File.ReadAllBytes(Path.Combine(Fixtures,"vendor-256-1024.symmetric.p7m"));
        foreach(var length in new[] {0,31,95,96,111,113})
            Assert.Throws<ArgumentException>(() => PasswordFileProtection.Decrypt(envelope[..length],"Test-șț-🔐-2026"));
        envelope[32] ^= 1;
        Assert.Throws<ArgumentException>(() => PasswordFileProtection.Decrypt(envelope,"Test-șț-🔐-2026"));
    }
}
