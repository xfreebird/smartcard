namespace MoldSign.Desktop;

/// <summary>Native dialogs supply input and display output without owning file transformation policy.</summary>
public interface IPasswordFileProcessor
{
    byte[]? Process(string input, FileProtectionOperation operation, string password);

    byte[] Encrypt(string input, string password, int keyBits)
    {
        // Existing processor implementations support the original AES-256 operation.
        if (keyBits != 256) throw new NotSupportedException();
        return Process(input, FileProtectionOperation.Encrypt, password) ?? throw new InvalidOperationException();
    }
}
