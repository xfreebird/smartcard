import SwiftUI
import UniformTypeIdentifiers
#if os(iOS)
import QuickLook
#endif

#if os(iOS)
/// A horizontal reveal keeps the containing document ScrollView vertically scrollable.
struct SwipeFileRow<Content: View>: View {
    let onRemove: () -> Void
    var removeLabel: String = L10n.text(.file_remove)
    var enabled: Bool = true
    @ViewBuilder let content: () -> Content
    @State private var offset: CGFloat = 0
    @State private var start: CGFloat = 0
    var body: some View {
        ZStack(alignment: .trailing) {
            Button(role: .destructive, action: onRemove) {
                Label(removeLabel, systemImage: "trash").labelStyle(.iconOnly)
                    .frame(width: 76).frame(maxHeight: .infinity)
                    .foregroundStyle(.white).background(.red)
            }.disabled(!enabled).opacity(offset < 0 ? 1 : 0).accessibilityHidden(offset == 0)
            content().frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .offset(x: offset)
                .simultaneousGesture(DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        guard enabled, abs(value.translation.width) > abs(value.translation.height) else { return }
                        offset = min(0, max(-76, start + value.translation.width))
                    }
                    .onEnded { value in
                        withAnimation(.snappy) { offset = offset < -30 ? -76 : 0; start = offset }
                    })
        }.clipped()
        .accessibilityAction(named: Text(removeLabel)) { if enabled { onRemove() } }
    }
}
#endif
