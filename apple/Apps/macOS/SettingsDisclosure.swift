import SwiftUI

/// Keep the native disclosure indicator while making its full title row actionable.
struct SettingsDisclosure<Content: View>: View {
    let title: L10n.Key
    @ViewBuilder var content: () -> Content
    @State private var expanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            content()
        } label: {
            Button { expanded.toggle() } label: {
                Text(L10n.text(title))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
