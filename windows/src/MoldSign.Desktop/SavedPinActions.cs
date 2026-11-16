namespace MoldSign.Desktop;

/// <summary>Card-scoped deletion must never remove another card's saved PIN.</summary>
public static class SavedPinActions
{
    public static bool ForgetSelected(IPinVault vault, string? certificateSha1, bool isDemo)
    {
        if (isDemo || string.IsNullOrWhiteSpace(certificateSha1) || !vault.Contains(certificateSha1)) return false;
        vault.Delete(certificateSha1);
        return true;
    }
}
