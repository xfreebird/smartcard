import SwiftUI

struct SettingsDisclosure<Content: View>: View {
    let title: L10n.Key
    @ViewBuilder var content: () -> Content

    var body: some View {
        FullWidthDisclosure(symbol: title == .ui_technical_details ? "slider.horizontal.3" : nil) {
            Text(L10n.text(title)).fontWeight(.medium)
        } content: {
            content()
        }
    }
}
