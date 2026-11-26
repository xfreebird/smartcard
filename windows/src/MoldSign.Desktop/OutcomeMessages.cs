using MoldSign.Core;

namespace MoldSign.Desktop;

/// <summary>
/// String-table keys for signing and verification outcomes (results, activity rows, tray recents). Demo wording
/// ("simulated", "not a valid signature") is chosen only while demo mode is on; a real session never gets it.
/// </summary>
public static class OutcomeMessages
{
    /// <summary>Prefix shared by every demo-only string key.</summary>
    public const string DemoKeyPrefix = "demo_";

    /// <summary>Activity row for one signed document; real rows are followed by the signature format label.</summary>
    public static string SignedActivityKey(bool demo) => demo ? "demo_sign_success" : "Activity_Signed";

    /// <summary>Result of a completed batch; the real message is formatted with the number of outputs.</summary>
    public static string BatchSignedKey(bool demo) => demo ? "demo_sign_success" : "Sign_Done";

    /// <summary>Activity row for one verified document.</summary>
    public static string VerifiedActivityKey(bool demo) => demo ? "demo_verify_success" : "Activity_Verified";

    /// <summary>Result of a completed verification. Debug screenshot capture shows the verdict even in demo mode.</summary>
    public static string VerificationKey(bool demo, bool screenshotCapture, Verdict? verdict) =>
        demo && !screenshotCapture ? "demo_verify_success" : verdict switch
        {
            Verdict.Valid => "Verdict_Valid",
            Verdict.Invalid => "Verdict_Invalid",
            Verdict.Indeterminate => "Verdict_Unknown",
            _ => "Verdict_Unsigned",
        };

    /// <summary>Message for a verification that did not complete.</summary>
    public static string VerificationFailureKey(VerificationStatus status) => status switch
    {
        // Only the demo session rejects files: a real session accepts every file the user selected.
        VerificationStatus.Rejected => "demo_fixture_only",
        VerificationStatus.Unsupported => "Error_NotImplemented",
        _ => "Verify_Failed",
    };
}
