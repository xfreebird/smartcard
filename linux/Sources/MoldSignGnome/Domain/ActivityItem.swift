import Foundation
import MoldSignKit

struct ActivityItem: Codable, Equatable {
    enum Kind: String, Codable { case signed, verified, bridge, failed, encrypted, decrypted }
    var id = UUID()
    var kind: Kind
    var title: String
    var subtitle: String
    var ok: Bool
    var date = Date()
    var filePath: String?

    var isProtectionOutput: Bool { kind == .encrypted || kind == .decrypted }
    var isSavedDocument: Bool { ok && filePath != nil && (kind == .signed || isProtectionOutput) }

    var isSignedDocument: Bool { kind == .signed && ok && filePath != nil }

    /// File entries are shown only while the file still exists; browser requests (no file) always are.
    var isShowable: Bool {
        filePath.map { FileManager.default.fileExists(atPath: $0) } ?? true
    }
}
