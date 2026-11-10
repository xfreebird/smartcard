import Foundation

struct ActivityItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var subtitle: String
    var ok: Bool
    var date = Date()
    var fileURL: URL?
    var documentRelativePath: String? = nil
    var signedOutput: Bool? = nil

    var protectionOperation: String? = nil

    var isSavedDocument: Bool { isSignedDocument || (ok && fileURL != nil && ["encrypt", "decrypt"].contains(protectionOperation ?? "")) }

    /// Legacy records predate the explicit signedOutput flag; verification never opts into the library.
    var isSignedDocument: Bool {
        ok && fileURL != nil && (signedOutput == true ||
            (signedOutput == nil && fileURL!.lastPathComponent.contains("-semnat")))
    }
}
