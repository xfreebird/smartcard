using System.Security.Cryptography.X509Certificates;

namespace MoldSign.App.Services;

public static class BridgeTls
{
    internal const string Password = "u9mUvI9BNb1U9jSbpBKf36YWINVK5XX5KAzql3bILNnjscVfLn";

    public static string IdentityPath =>
        Environment.GetEnvironmentVariable("MSIGN_TLS_P12") ??
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "MoldSign", "localhost.p12");

    public static X509Certificate2Collection Load(string path)
    {
        if (!File.Exists(path))
            throw new FileNotFoundException("localhost.p12", path);
        // Schannel cannot serve TLS with an ephemeral PKCS#12 private key on Windows.
        var storage = OperatingSystem.IsWindows() ? X509KeyStorageFlags.UserKeySet : X509KeyStorageFlags.EphemeralKeySet;
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
