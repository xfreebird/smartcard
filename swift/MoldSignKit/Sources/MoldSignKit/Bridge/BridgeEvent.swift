import Foundation

public struct BridgeEvent: Sendable {
    public let origin: String?
    public let method: String
    public let path: String
    public let status: Int
}
