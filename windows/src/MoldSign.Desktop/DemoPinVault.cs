namespace MoldSign.Desktop;

/// <summary>No credential container is opened and no PIN is retained in the sample sandbox.</summary>
public sealed class DemoPinVault : IPinVault
{
    public void Save(string pin, string certificateSha1) { }
    public bool Contains(string certificateSha1) => false;
    public Task<string?> LoadAsync(string certificateSha1, string reason) => Task.FromResult<string?>(null);
    public void Delete(string certificateSha1) { }
    public void DeleteAll() { }
    public IReadOnlyList<string> SavedCards() => [];
}
