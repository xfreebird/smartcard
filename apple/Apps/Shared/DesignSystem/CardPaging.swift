import SwiftUI

/// Use the native behavior directly so SwiftUI registers view-aligned scroll targets as well as snapping.
struct CardPaging: ViewModifier {
    let interactionChanged: (Bool) -> Void
    @State private var legacyHorizontalDrag = false

    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            #if compiler(>=6.2)
            content.scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne, anchor: .center))
                .onScrollPhaseChange { _, phase in phaseChanged(phase) }
            #else
            // Xcode 16 can target older systems but does not contain the iOS 26 anchor overload.
            content.scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
                .onScrollPhaseChange { _, phase in phaseChanged(phase) }
            #endif
        } else if #available(iOS 18.0, macOS 15.0, *) {
            content.scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
                .onScrollPhaseChange { _, phase in phaseChanged(phase) }
        } else {
            content.scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                .simultaneousGesture(DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        if abs(value.translation.width) > abs(value.translation.height) {
                            legacyHorizontalDrag = true
                            interactionChanged(true)
                        }
                    }
                    .onEnded { _ in
                        if legacyHorizontalDrag { legacyHorizontalDrag = false; interactionChanged(false) }
                    })
        }
    }

    @available(iOS 18.0, macOS 15.0, *)
    private func phaseChanged(_ phase: ScrollPhase) {
        switch phase {
        case .tracking, .interacting, .decelerating: interactionChanged(true)
        case .idle: interactionChanged(false)
        default: break
        }
    }
}
