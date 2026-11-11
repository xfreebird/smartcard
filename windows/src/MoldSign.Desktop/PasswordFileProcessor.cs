using MoldSign.Core.Protection;

namespace MoldSign.Desktop;

public sealed class PasswordFileProcessor : IPasswordFileProcessor
{
    public byte[]? Process(string input, FileProtectionOperation operation, string password)
    {
        if (operation == FileProtectionOperation.Remove)
        {
            ProtectedFileIO.OverwriteAndRemove(input);
            return null;
        }
        if (operation is not (FileProtectionOperation.Encrypt or FileProtectionOperation.Decrypt))
            throw new ArgumentOutOfRangeException(nameof(operation));
        var bytes = ProtectedFileIO.Read(input);
        try
        {
            return operation == FileProtectionOperation.Encrypt
                ? PasswordFileProtection.Encrypt(bytes, password)
                : PasswordFileProtection.Decrypt(bytes, password);
        }
        finally { System.Security.Cryptography.CryptographicOperations.ZeroMemory(bytes); }
    }
}
