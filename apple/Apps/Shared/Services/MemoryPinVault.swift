import Foundation

/// Isolated credential dependency: demo PINs remain in memory and never reach the system keychain.
final class MemoryPinVault: PinStoring {
    private var pins: [String: String] = [:]
    func savedAccounts() -> [String] { pins.keys.sorted() }
    func hasPIN(certID: String) -> Bool { pins[certID] != nil }
    func save(_ pin: String, certID: String) throws { pins[certID] = pin }
    func load(certID: String, reason: String) async -> String? { pins[certID] }
    func delete(certID: String) { pins[certID] = nil }
}
