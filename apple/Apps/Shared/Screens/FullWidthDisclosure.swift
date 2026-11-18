import SwiftUI

/// One focusable row owns the disclosure action, its chevron, and its expansion animation.
struct FullWidthDisclosure<Title: View, Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false
    var captureKey: String? = nil
    var symbol: String? = nil
    @ViewBuilder var title: () -> Title
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.20)) {
                    expanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    if let symbol {
                        Image(systemName: symbol)
                            .font(.body.weight(.medium))
                            .foregroundStyle(Theme.brand)
                            .accessibilityHidden(true)
                    }
                    title().frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                #if os(iOS)
                .frame(minHeight: 44)
                #else
                .frame(minHeight: 32)
                #endif
                .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(L10n.text(expanded ? .disclosure_expanded : .disclosure_collapsed))
            .accessibilityIdentifier("verify.disclosure." + (captureKey ?? "section"))
            if expanded {
                VStack(alignment: .leading, spacing: 12) { content() }
                    .padding(.horizontal, 4).padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }
        }
        .onAppear {
            #if DEBUG
            let env = ProcessInfo.processInfo.environment
            if env["MSIGN_SCREENSHOT_CAPTURE"] == "1", env["MSIGN_QA_NO_HARDWARE"] == "1",
               env["MSIGN_DEMO_CARDS"] != nil, env["MSIGN_DEMO_PREFERENCES_SUITE"]?.hasPrefix("md.esemnbun.qa.") == true,
               let target = env["MSIGN_CAPTURE_EXPAND"], let captureKey {
                expanded = target == "all" || target == captureKey || captureKey == "signature"
            }
            #endif
        }
    }
}
