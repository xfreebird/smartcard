import SwiftUI

/// Empty states are cards too: no reader, reader without card, error.
struct EmptyCardFace: View {
    let content: EmptyCardContent
    var compact = false
    var showsAction = true
    var onAction: () -> Void = {}

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        VStack(spacing: Theme.Space.s) {
            Image(systemName: content.symbol)
                .font(.system(size: compact ? 26 : 32, weight: .regular))
                .foregroundStyle(content.isError ? Color.red : .secondary)
                .symbolEffect(.pulse, isActive: content.isReading)
            Text(content.title).font(.headline).multilineTextAlignment(.center)
            Text(content.subtitle).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            if showsAction, let actionTitle = content.actionTitle {
                Button(actionTitle, action: onAction)
                    .nativeButtonStyle(.automatic)
                    .font(.caption.weight(.semibold))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(content.isError ? Color.red.opacity(0.08) : Color.secondary.opacity(0.06), in: shape)
        .overlay(shape.strokeBorder(content.isError ? Color.red.opacity(0.5) : Color.secondary.opacity(0.40),
                                    lineWidth: 1))
        .accessibilityElement(children: .contain)
    }

}
