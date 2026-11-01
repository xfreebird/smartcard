import SwiftUI

/// Shared content for the About window and Settings, so they cannot drift apart.
struct AboutContent: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    var body: some View {
        VStack(spacing: 12) {
            #if os(macOS)
            Image(nsImage: NSApp.applicationIconImage)
                .resizable().interpolation(.high).frame(width: 80, height: 80)
            #else
            Image("AboutIcon").resizable().interpolation(.high)
                .frame(width: 80, height: 80).clipShape(RoundedRectangle(cornerRadius: 18))
            #endif
            Text(verbatim: "eSemnBun").font(.title2.bold())
            Text(version).foregroundStyle(.secondary)
            Text(verbatim: "Nicolae Ghimbovschi")
            Link("esemnbun.md", destination: URL(string: "https://esemnbun.md")!)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .navigationTitle(L10n.text(.about_app_title))
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 340)
        #endif
    }
}
