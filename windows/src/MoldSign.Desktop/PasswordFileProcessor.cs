using MoldSign.Core.Protection;

namespace MoldSign.Desktop;

public sealed class PasswordFileProcessor : IPasswordFileProcessor
{
    public byte[] Encrypt(string input, string password, int keyBits) =>
        Transform(input, bytes => PasswordFileProtection.Encrypt(bytes, password, keyBits));

    public byte[]? Process(string input, FileProtectionOperation operation, string password)
    {
        if (operation == FileProtectionOperation.Remove)
        {
            ProtectedFileIO.OverwriteAndRemove(input);
            return null;
        }
        return operation switch
        {
            FileProtectionOperation.Encrypt => Encrypt(input, password, 256),
            FileProtectionOperation.Decrypt => Transform(input, bytes => PasswordFileProtection.Decrypt(bytes, password)),
            _ => throw new ArgumentOutOfRangeException(nameof(operation)),
        };
    }

    private static byte[] Transform(string input, Func<byte[], byte[]> transform)
    {
        var bytes = ProtectedFileIO.Read(input);
        try { return transform(bytes); }
        finally { System.Security.Cryptography.CryptographicOperations.ZeroMemory(bytes); }
    }
}
