import SwiftUI
import UniformTypeIdentifiers
import MoldSignKit

struct FullWidthDisclosure<Title: View, Content: View>: View {
    @State private var expanded = false
    var captureKey: String? = nil
    @ViewBuilder var title: () -> Title
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button { expanded.toggle() } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right").frame(width: 14).padding(.top, 3)
                    title().frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(expanded ? "Expanded" : "Collapsed")
            .accessibilityIdentifier("verify.disclosure." + (captureKey ?? "section"))
            if expanded { content().padding(.leading, 24) }
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
