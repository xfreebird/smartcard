import SwiftUI
import MoldSignKit

/// A browser asking for a signature (SEC-02).
struct ConsentRequest: Identifiable {
    let id = UUID()
    let request: BridgeRequest
    let holder: String
    let hasStoredPIN: Bool

    var originHost: String {
        request.origin.flatMap { URL(string: $0)?.host } ?? L10n.text(.ui_local_application)
    }

    /// The request payload identifies every document where the bridge knows it.
    /// Keep the fallback in the presentation model so older portals that only send
    /// opaque data still get an accurate, non-empty consent summary.
    var documentNames: [String] {
        request.documentNames.isEmpty
            ? [request.documentName ?? L10n.text(.ui_data_to_sign)]
            : request.documentNames
    }

    var contentSummary: String {
        let bytes = request.contentBytes.map { ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .file) }
            ?? L10n.text(.ui_content_size_unknown)
        return L10n.text(.ui_consent_content_count_size, request.documentCount, bytes)
    }
}
