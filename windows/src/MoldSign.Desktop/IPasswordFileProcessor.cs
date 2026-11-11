namespace MoldSign.Desktop;

/// <summary>Native dialogs supply input and display output without owning file transformation policy.</summary>
public interface IPasswordFileProcessor
{
    byte[]? Process(string input, FileProtectionOperation operation, string password);
}
