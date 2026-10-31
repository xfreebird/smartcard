namespace MoldSign.Desktop;

/// <summary>Credential boundary. Implementations decide how OS authentication gates release of a saved PIN.</summary>
public interface IPinVault
{
    void Save(string pin, string certificateSha1);
    bool Contains(string certificateSha1);
    Task<string?> LoadAsync(string certificateSha1, string reason);
    void Delete(string certificateSha1);
    void DeleteAll();
    IReadOnlyList<string> SavedCards();
}
