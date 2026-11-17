import Foundation

/// What a bridge caller asks for: shown in the consent UI (SEC-02).
public struct BridgeRequest: Sendable {
    public enum Operation: String, Sendable { case signData, signPDF, signFile }
    public let origin: String?
    public let operation: Operation
    public let documentName: String?
    /// Individual names are retained for the host consent sheet.  Older callers
    /// which only supplied `documentName` remain source-compatible.
    public let documentNames: [String]
    /// Exact request content size, when the bridge receives bytes or can inspect a
    /// local file.  The authorization UI must not claim a size it cannot establish.
    public let contentBytes: Int?
    public let format: String?
    /// The caller already sent a PIN (typed into the web page); the host should not ask for one.
    public let pinIncluded: Bool
    /// An on-demand card requires a native PIN prompt; webpage PIN fields are ignored.
    public internal(set) var requiresNativePIN = false
    /// Requested digest ("SHA-1" / "SHA-256"); honoured for XAdES (R-11).
    public internal(set) var algorithm: String? = nil
    /// `use_pin_session` of a multi-document portal batch: the first document's session id (MAC-19).
    public internal(set) var batchSession: String? = nil
    /// The certificate the page picked from `/certificates` (several cards may be connected): SHA-1 + holder.
    /// Consent and PIN must be for this card; the server signs with the reader that holds it.
    public internal(set) var certificateSHA1: String? = nil
    public internal(set) var certificateHolder: String? = nil

    public var documentCount: Int { max(1, documentNames.count) }

    public init(origin: String?, operation: Operation, documentName: String?,
                documentNames: [String] = [], contentBytes: Int? = nil,
                format: String?, pinIncluded: Bool, algorithm: String? = nil,
                batchSession: String? = nil) {
        self.origin = origin
        self.operation = operation
        self.documentName = documentName
        self.documentNames = documentNames
        self.contentBytes = contentBytes
        self.format = format
        self.pinIncluded = pinIncluded
        self.algorithm = algorithm
        self.batchSession = batchSession
    }
}
