import SwiftUI
import MoldSignKit

/// Empty states are cards too: no reader, reader without card, error.
struct EmptyCardFace: View {
    let status: ReaderStatus
    var size: CardSelector.Size
    @State private var showGuide = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        VStack(spacing: Theme.Space.s) {
            Image(systemName: symbol)
                .font(.system(size: size == .compact ? 26 : 32, weight: .regular))
                .foregroundStyle(isError ? Color.red : .secondary)
                .symbolEffect(.pulse, isActive: isReading)
            Text(status.title).font(.headline).multilineTextAlignment(.center)
            Text(status.subtitle).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            #if os(iOS)
            if case .noReader = status {
                Button(L10n.text(.ui_how_do_i_connect_the_reader)) { showGuide = true }
                    .font(.caption.weight(.semibold))
                    .sheet(isPresented: $showGuide) { ConnectionGuideView() }
            }
            #endif
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isError ? Color.red.opacity(0.08) : Color.secondary.opacity(0.06), in: shape)
        .overlay(shape.strokeBorder(isError ? Color.red.opacity(0.5) : Color.secondary.opacity(0.40),
                                    lineWidth: 1))
        .accessibilityElement(children: .contain)
    }

    private var isError: Bool {
        switch status {
        case .error, .unavailable: return true
        default: return false
        }
    }

    private var isReading: Bool {
        if case .reading = status { return true }
        return false
    }

    private var symbol: String {
        switch status {
        case .noReader: return "cable.connector"
        case .empty: return "creditcard"
        case .reading: return "creditcard.viewfinder"
        case .error, .unavailable: return "exclamationmark.triangle"
        default: return "creditcard"
        }
    }
}
