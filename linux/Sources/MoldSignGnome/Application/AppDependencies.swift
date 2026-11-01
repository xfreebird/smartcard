import Dispatch
import Foundation
import MoldSignKit

/// Narrow platform seams let tests replace PC/SC monitoring and the Secret Service.
protocol CardMonitoring: AnyObject {
    var onChange: ((ReaderSnapshot) -> Void)? { get set }
    func start(interval: DispatchTimeInterval)
    func stop()
    func refresh()
}

protocol PINStoring: AnyObject {
    func save(_ pin: String, certID: String, holder: String) throws
    func load(certID: String) -> PINLookup
    func hasPIN(certID: String) -> Bool
    @discardableResult func delete(certID: String) -> Bool
    func deleteAll() -> Bool
    func availabilityProblem() -> String?
}

protocol BridgeHosting: AnyObject {
    var allowsLegacyDesktopClient: Bool { get set }
    var state: BridgeState { get }
    var authorize: ((BridgeRequest, @escaping (BridgeDecision) -> Void) -> Void)? { get set }
    var onSignResult: ((BridgeRequest, Error?) -> Void)? { get set }
    var onStateChange: (() -> Void)? { get set }
    func start()
    func stop()
}

protocol DocumentVerifying {
    func verify(_ url: URL) -> [SignatureReport]
}

// Test bridges can ignore the legacy-client capability; production BridgeHost owns it.
extension BridgeHosting {
    var allowsLegacyDesktopClient: Bool { get { false } set {} }
}
