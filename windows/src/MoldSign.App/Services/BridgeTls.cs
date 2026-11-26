using System.Security.Cryptography.X509Certificates;

namespace MoldSign.App.Services;

public static class BridgeTls
{
    internal const string Password = "u9mUvI9BNb1U9jSbpBKf36YWINVK5XX5KAzql3bILNnjscVfLn";

    public static string IdentityPath =>
        Environment.GetEnvironmentVariable("MSIGN_TLS_P12") ??
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "MoldSign", "localhost.p12");

    /// Copy shipped next to the exe (MSI/MSIX, D-03).
    public static string BundledPath => Path.Combine(AppContext.BaseDirectory, "localhost.p12");

    /// Identity the bridge serves: `MSIGN_TLS_P12`, then an imported copy, then the bundled one.
    public static string ResolvePath() =>
        Environment.GetEnvironmentVariable("MSIGN_TLS_P12") is { } env ? env
        : File.Exists(IdentityPath) ? IdentityPath
        : BundledPath;

    public static X509Certificate2Collection Load(string path)
    {
        if (!File.Exists(path))
            throw new FileNotFoundException("localhost.p12", path);
        // Schannel cannot serve TLS with an ephemeral PKCS#12 private key on Windows, and macOS has no ephemeral key
        // storage (the portable bridge tests run there); Linux keeps the key in memory only.
        var storage = OperatingSystem.IsWindows() ? X509KeyStorageFlags.UserKeySet
            : OperatingSystem.IsMacOS() ? X509KeyStorageFlags.DefaultKeySet : X509KeyStorageFlags.EphemeralKeySet;
        var certificates = X509CertificateLoader.LoadPkcs12CollectionFromFile(path, Password, storage);
        var leaf = certificates.FirstOrDefault(c => c.HasPrivateKey);
        if (leaf is null || !string.Equals(leaf.GetNameInfo(X509NameType.DnsName, false), "localhost.cts.md",
                StringComparison.OrdinalIgnoreCase) || leaf.NotAfter.ToUniversalTime() <= DateTime.UtcNow)
        {
            foreach (var certificate in certificates) certificate.Dispose();
            throw new System.Security.Cryptography.CryptographicException("Invalid localhost.cts.md identity");
        }
        return certificates;
    }
}
