import Foundation

/// A durable fail-closed marker survives process crashes and automatic host restarts.
/// Begin before VERIFY; complete only after the signed output is safely stored.
/// Failure deliberately leaves the marker for an operator to inspect and remove.
public final class UnattendedSigningGate {
    public static let markerName = ".unattended-signing-lock"
    private let root: TrustedRoot
    private var token: Data?

    public init(root: TrustedRoot) { self.root = root }

    public func begin() throws {
        guard token == nil else { throw MCPFailure.signingDisabled }
        let candidate = Data(UUID().uuidString.utf8)
        do { try root.writeExclusive(Self.markerName, data: candidate) }
        catch { throw MCPFailure.signingDisabled }
        token = candidate
    }

    public func complete() throws {
        guard let token,
              let stored = try? root.read(Self.markerName, limit: 128, privateFile: true),
              stored == token else { throw MCPFailure.signingDisabled }
        do { try root.remove(Self.markerName) }
        catch { throw MCPFailure.signingDisabled }
        self.token = nil
    }
}
