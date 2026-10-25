import Foundation
#if canImport(CryptoTokenKit)
import CryptoTokenKit
#endif
import CPCSC

/// Raw APDU pipe to a card (docs/09 §3.1). The response includes SW1 SW2;
/// `CosmoXCard` handles `61xx` GET RESPONSE itself.
public protocol CardTransport: AnyObject {
    var readerName: String { get }
    func transmit(_ apdu: Data) throws -> Data
    func disconnect()
}

public enum CardTransports {
    /// The proven transport per platform: PC/SC on macOS and Linux, CryptoTokenKit on iOS.
    public static func connectDefault() throws -> CardTransport {
        try connect(reader: nil)
    }

    /// `reader` nil → the first reader that holds a card.
    public static func connect(reader: String?) throws -> CardTransport {
        #if os(macOS) || os(Linux)
        return try PCSCTransport(readerName: reader)
        #else
        return try TKSmartCardTransport.connect(slotName: reader)
        #endif
    }

    /// Readers currently holding a card that answers (several eID cards can be connected at once).
    public static func readersWithCards() -> [String] {
        #if os(macOS) || os(Linux)
        return PCSCTransport.readerStates().filter { $0.cardPresent && !$0.mute }.map(\.name)
        #elseif canImport(CryptoTokenKit)
        guard let manager = TKSmartCardSlotManager.default else { return [] }
        return manager.slotNames.filter { manager.slotNamed($0)?.state == .validCard }
        #else
        return []
        #endif
    }
}

// MARK: - PC/SC (macOS PCSC.framework, Linux pcsc-lite)

#if os(macOS) || os(Linux)
public final class PCSCTransport: CardTransport {
    public struct ReaderState: Equatable, Sendable {
        public let name: String
        public let cardPresent: Bool
        /// Card inserted but not answering to reset.
        public let mute: Bool
        /// Card insert/remove counter from the upper 16 bits of `dwEventState` (pcsc-lite). A change means the
        /// card was removed and reinserted (or swapped) even if both happened between two polls. 0 where the
        /// stack doesn't report it (macOS's PC/SC shim), so hosts also watch `cardPresent`.
        public let eventCount: Int
    }

    public let readerName: String
    public private(set) var activeProtocol: UInt32 = 0
    private var ctx: Int64 = 0
    private var hCard: Int64 = 0

    /// Names of all PC/SC readers currently attached.
    public static func readerNames() -> [String] {
        var ctx: Int64 = 0
        guard c_scard_establish(0, &ctx) == 0 else { return [] }
        defer { _ = c_scard_release(&ctx) }
        var bufLen: UInt32 = 4096
        var buf = [CChar](repeating: 0, count: Int(bufLen))
        guard c_scard_list_readers(&ctx, &buf, &bufLen) == 0, bufLen > 1 else { return [] }
        // multi-string: "a\0b\0\0"
        return buf.prefix(Int(bufLen)).split(separator: 0).map { String(cString: Array($0) + [0]) }
    }

    /// The PC/SC service answers (Linux: `pcscd` running). False → "service unavailable", distinct from "no reader".
    public static func isServiceAvailable() -> Bool {
        var ctx: Int64 = 0
        guard c_scard_establish(0, &ctx) == 0 else { return false }
        _ = c_scard_release(&ctx)
        return true
    }

    /// Readers and card presence without connecting (SCardGetStatusChange, timeout 0). Used for
    /// hot-plug polling where CryptoTokenKit is unavailable (Linux, LNX-08).
    public static func readerStates() -> [ReaderState] {
        var ctx: Int64 = 0
        guard c_scard_establish(0, &ctx) == 0 else { return [] }
        defer { _ = c_scard_release(&ctx) }
        var bufLen: UInt32 = 4096
        var buf = [CChar](repeating: 0, count: Int(bufLen))
        guard c_scard_list_readers(&ctx, &buf, &bufLen) == 0, bufLen > 1 else { return [] }
        let names = buf.prefix(Int(bufLen)).split(separator: 0).map { String(cString: Array($0) + [0]) }
        return names.map { name in
            var state: UInt32 = 0
            _ = c_scard_reader_state(&ctx, name, &state)
            return ReaderState(name: name, cardPresent: state & 0x20 != 0, mute: state & 0x200 != 0,
                               eventCount: Int(state >> 16))
        }
    }

    /// Connects (SHARED, T0|T1) to `readerName`, or to the first reader when nil.
    public init(readerName: String? = nil) throws {
        var ctx: Int64 = 0
        let rv = c_scard_establish(0, &ctx) // SCARD_SCOPE_USER = 0
        guard rv == 0 else { throw CardError.noReader }
        self.ctx = ctx

        let name: String
        if let readerName {
            name = readerName
        } else if let withCard = Self.readerStates().first(where: { $0.cardPresent && !$0.mute }) {
            name = withCard.name     // several readers: take the one holding a card
        } else {
            var bufLen: UInt32 = 4096
            var readersBuf = [CChar](repeating: 0, count: Int(bufLen))
            let rv2 = c_scard_list_readers(&ctx, &readersBuf, &bufLen)
            guard rv2 == 0, bufLen > 1 else { _ = c_scard_release(&self.ctx); throw CardError.noReader }
            name = String(cString: readersBuf)
        }
        self.readerName = name
        MSLog.info("Reader: \(name)")

        var hCard: Int64 = 0
        var proto: UInt32 = 0
        let rv3 = c_scard_connect(&ctx, name, 2, 3, &hCard, &proto) // shared, T0|T1
        guard rv3 == 0 else { _ = c_scard_release(&self.ctx); throw CardError.noCard }
        self.hCard = hCard
        self.activeProtocol = proto
        MSLog.info("Connected, protocol: \(proto)")
    }

    deinit { disconnect() }

    /// Warm reset (SCARD_RESET_CARD): drops stale SM state left by a crashed session.
    /// TODO(MAC-12): docs/01 says to always do this on connect; verify on device before making it default.
    public func reset() throws {
        var proto: UInt32 = 0
        guard c_scard_reconnect(&hCard, 2, 3, 1, &proto) == 0 else { throw CardError.cardNotResponding }
        activeProtocol = proto
    }

    public func transmit(_ apdu: Data) throws -> Data {
        let sendBytes = [UInt8](apdu)
        var recvBuf = [UInt8](repeating: 0, count: 65536)
        var recvLen: UInt32 = UInt32(recvBuf.count)
        let rv = c_scard_transmit(&hCard, sendBytes, UInt32(sendBytes.count), &recvBuf, &recvLen)
        guard rv == 0, recvLen >= 2 else { throw CardError.cardNotResponding }
        return Data(recvBuf[0..<Int(recvLen)])
    }

    public func disconnect() {
        if hCard != 0 { _ = c_scard_disconnect(&hCard, 0); hCard = 0 }
        if ctx != 0 { _ = c_scard_release(&ctx); ctx = 0 }
    }
}
#endif

// MARK: - CryptoTokenKit (iOS; macOS needs the com.apple.security.smartcard entitlement)

#if canImport(CryptoTokenKit)
/// USB CCID readers on iPhone/iPad (USB-C or Lightning camera adapter) and, with the entitlement, on macOS.
/// The core is synchronous, so TK's async replies are bridged with semaphores: never call from the main thread.
public final class TKSmartCardTransport: CardTransport {
    public let readerName: String
    private let card: TKSmartCard
    private let timeout: TimeInterval

    private init(readerName: String, card: TKSmartCard, timeout: TimeInterval) {
        self.readerName = readerName
        self.card = card
        self.timeout = timeout
    }

    /// Opens an exclusive session on `slotName`, or on the first slot holding a responsive card.
    /// TODO(IOS-02): check on device whether a stale SM session needs an explicit reset here.
    public static func connect(slotName: String? = nil, timeout: TimeInterval = 15) throws -> TKSmartCardTransport {
        guard let manager = TKSmartCardSlotManager.default else { throw CardError.noReader }
        let names = slotName.map { [$0] } ?? manager.slotNames
        guard !names.isEmpty else { throw CardError.noReader }
        for name in names {
            guard let slot = manager.slotNamed(name), slot.state == .validCard,
                  let card = slot.makeSmartCard() else { continue }
            let done = DispatchSemaphore(value: 0)
            var began = false
            card.beginSession { success, _ in began = success; done.signal() }
            guard done.wait(timeout: .now() + timeout) == .success, began else { throw CardError.cardNotResponding }
            MSLog.info("Reader: \(name)")
            return TKSmartCardTransport(readerName: name, card: card, timeout: timeout)
        }
        throw CardError.noCard
    }

    public func transmit(_ apdu: Data) throws -> Data {
        let done = DispatchSemaphore(value: 0)
        var response: Data?
        card.transmit(apdu) { reply, _ in response = reply; done.signal() }
        guard done.wait(timeout: .now() + timeout) == .success,
              let response, response.count >= 2 else { throw CardError.cardNotResponding }
        return response
    }

    public func disconnect() { card.endSession() }
}
#endif
