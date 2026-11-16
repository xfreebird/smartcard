using Windows.Security.Credentials;
using MoldSign.Desktop;
using Windows.Security.Credentials.UI;

namespace MoldSign.App.Services;

/// <summary>
/// PinVault (docs/09 §3.5, WIN-05, SEC-05): Credential Locker (<see cref="PasswordVault"/>) keyed by the
/// card certificate SHA-1, so a different card never receives another card's PIN. Every read is gated by
/// Windows Hello / device PIN through <see cref="UserConsentVerifier"/>. Deleted on a wrong PIN.
/// Never logged.
/// </summary>
/// <param name="ownerWindow">HWND that owns the Windows Hello prompt (0 = none).</param>
public sealed class PinVault(Func<nint> ownerWindow, bool isolated = false) : IPinVault
{
    private const string Resource = "MoldSign.QSCD-PIN";
    private const int ElementNotFound = unchecked((int)0x80070490);

    private readonly PasswordVault _vault = new();

    /// <summary>Stores (or replaces) the PIN for the card identified by <paramref name="certSha1"/>.</summary>
    public void Save(string pin, string certSha1)
    {
        if (isolated) return;
        ArgumentException.ThrowIfNullOrEmpty(pin);
        ArgumentException.ThrowIfNullOrEmpty(certSha1);
        Delete(certSha1);
        _vault.Add(new PasswordCredential(Resource, certSha1, pin));
    }

    public bool Contains(string certSha1)
    {
        if (isolated) return false;
        try
        {
            return _vault.FindAllByResource(Resource).Any(c => c.UserName == certSha1);
        }
        catch (Exception e) when (e.HResult == ElementNotFound)
        {
            return false;
        }
    }

    /// <summary>
    /// The stored PIN after a successful Windows Hello verification, or null (none stored, Hello not
    /// configured). User cancellation aborts the consent instead of opening another PIN prompt.
    /// Without an available verifier the PIN is NOT released.
    /// </summary>
    public async Task<string?> LoadAsync(string certSha1, string reason)
    {
        if (!Contains(certSha1)) return null;

        var availability = await UserConsentVerifier.CheckAvailabilityAsync();
        if (availability != UserConsentVerifierAvailability.Available) return null;

        // In an unpackaged Win32 app the prompt must be owned by our window, or it can open behind it.
        var hwnd = ownerWindow();
        var result = hwnd != 0
            ? await UserConsentVerifierInterop.RequestVerificationForWindowAsync(hwnd, reason)
            : await UserConsentVerifier.RequestVerificationAsync(reason);
        if (result == UserConsentVerificationResult.Canceled) throw new OperationCanceledException();
        if (result != UserConsentVerificationResult.Verified) return null;

        try
        {
            var credential = _vault.Retrieve(Resource, certSha1);
            credential.RetrievePassword();
            return credential.Password;
        }
        catch (Exception e) when (e.HResult == ElementNotFound)
        {
            return null;
        }
    }

    public void Delete(string certSha1)
    {
        if (isolated) return;
        try
        {
            _vault.Remove(_vault.Retrieve(Resource, certSha1));
        }
        catch (Exception e) when (e.HResult == ElementNotFound)
        {
            // Nothing stored.
        }
    }

    /// <summary>Only certificate identifiers; never retrieves credential passwords.</summary>
    public IReadOnlyList<string> SavedCards()
    {
        if (isolated) return [];
        try { return _vault.FindAllByResource(Resource).Select(c => c.UserName).ToArray(); }
        catch (Exception e) when (e.HResult == ElementNotFound) { return []; }
    }

    /// <summary>Remove every stored PIN only for explicit all-card actions.</summary>
    public void DeleteAll()
    {
        if (isolated) return;
        try
        {
            foreach (var credential in _vault.FindAllByResource(Resource)) _vault.Remove(credential);
        }
        catch (Exception e) when (e.HResult == ElementNotFound)
        {
            // Nothing stored.
        }
    }
}
