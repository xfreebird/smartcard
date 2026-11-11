import SwiftUI
import MoldSignKit

/// The one-glance "can I sign?" light (docs/10 §0.1, UX-01). Color is never the only signal: `label` says it too.
enum StatusLight: Equatable {
    case idle, reader, ready, busy, error

    var color: Color? {
        switch self {
        case .idle: return nil
        case .reader: return .orange
        case .ready: return .green
        case .busy: return .blue
        case .error: return .red
        }
    }
}
