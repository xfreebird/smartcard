/// Demo-only wording: the "fictional data" banner, tray label and status text, the sample-output notice,
/// "Demo signing completed" and the browser placeholder. Every flag is off outside demo mode, so real
/// reader/NFC signing, results, documents, settings, the menu bar and widgets never show them.
struct DemoNotices: Equatable {
    /// Banners on workspaces, the menu-bar label and the status line.
    let banner: Bool
    /// Result rows and summaries say the output is a simulated sample, not a valid signature.
    let simulatedResults: Bool
    /// The portal browser is replaced by the demo explanation (no portal traffic in demo mode).
    let replacesBrowser: Bool

    /// `screenshotCapture` is the isolated Debug capture fixture, which runs only in demo mode.
    init(demoMode: Bool, screenshotCapture: Bool) {
        banner = demoMode && !screenshotCapture
        simulatedResults = demoMode
        replacesBrowser = demoMode && !screenshotCapture
    }
}
