import SwiftUI

@MainActor @Observable
final class MonitoringPreferences {
    static let shared = MonitoringPreferences()
    private(set) var consent = MonitoringConsent.load(from: AppPreferencesStore.defaults)

    var shouldAsk: Bool {
        guard !consent.decided else { return false }
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        if env["MSIGN_DEMO_CARDS"] != nil && env["MSIGN_SENTRY_CONSENT_QA"] != "1" { return false }
        #endif
        return true
    }

    func choose(crashes: Bool, metrics: Bool) {
        consent = MonitoringConsent(decided: true, crashes: crashes, metrics: metrics)
        consent.save(to: AppPreferencesStore.defaults)
        AppMonitoring.start()
    }
}

struct MonitoringConsentPrompt: ViewModifier {
    @State private var presenting = false
    func body(content: Content) -> some View {
        content
            .onAppear { presenting = MonitoringPreferences.shared.shouldAsk }
            .sheet(isPresented: $presenting) {
                MonitoringConsentView {
                    presenting = false
                }
                .interactiveDismissDisabled()
            }
    }
}

private struct MonitoringConsentView: View {
    @State private var crashes = false
    @State private var metrics = false
    let dismiss: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(L10n.text(.monitoring_title)).font(.title2.bold())
            Text(L10n.text(.monitoring_description)).fixedSize(horizontal: false, vertical: true)
            Toggle(L10n.text(.monitoring_crash), isOn: $crashes)
                .accessibilityIdentifier("monitoring.crashes")
            Toggle(L10n.text(.monitoring_metrics), isOn: $metrics)
                .accessibilityIdentifier("monitoring.metrics")
            Text(L10n.text(.monitoring_settings_hint)).font(.caption).foregroundStyle(.secondary)
            HStack {
                Button(L10n.text(.monitoring_decline)) {
                    MonitoringPreferences.shared.choose(crashes: false, metrics: false)
                    dismiss()
                }.accessibilityIdentifier("monitoring.decline")
                Spacer()
                Button(L10n.text(.monitoring_allow)) {
                    MonitoringPreferences.shared.choose(crashes: crashes, metrics: metrics)
                    dismiss()
                }.buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("monitoring.allow")
            }
        }
        .padding(28)
        .frame(width: 460)
    }
}

struct MonitoringSettings: View {
    var body: some View {
        Section(L10n.text(.monitoring_title)) {
            Toggle(L10n.text(.monitoring_crash), isOn: Binding(
                get: { MonitoringPreferences.shared.consent.crashes },
                set: { MonitoringPreferences.shared.choose(crashes: $0, metrics: MonitoringPreferences.shared.consent.metrics) }
            ))
            Toggle(L10n.text(.monitoring_metrics), isOn: Binding(
                get: { MonitoringPreferences.shared.consent.metrics },
                set: { MonitoringPreferences.shared.choose(crashes: MonitoringPreferences.shared.consent.crashes, metrics: $0) }
            ))
            Text(L10n.text(.monitoring_settings_hint)).font(.caption).foregroundStyle(.secondary)
        }
    }
}
