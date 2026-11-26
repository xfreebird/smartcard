import Foundation
import MoldSignKit

/// One browser signature's Core NFC connection. Bridge workers transmit through it; the first
/// disconnect or failure closes the NFC session exactly once.
final class NFCBrowserTransport: ContactlessBridgeTransport, @unchecked Sendable {
    let readerName = "Core NFC browser"
    let transport: CardTransport
    private let close: @Sendable (Error?) -> Void
    private let lock = NSLock()
    private var closed = false
    init(transport: CardTransport, close: @escaping @Sendable (Error?) -> Void) {
        self.transport = transport; self.close = close
    }
    func transmit(_ apdu: Data) throws -> Data { try transport.transmit(apdu) }
    func disconnect() { finish(error: nil) }
    func finish(error: Error?) {
        lock.lock()
        guard !closed else { lock.unlock(); return }
        closed = true
        lock.unlock()
        transport.disconnect()
        close(error)
    }
}

/// Only bridge worker threads wait here. Main-actor callbacks continue servicing Core NFC.
final class NFCBrowserResult<T>: @unchecked Sendable {
    var result: Result<T, Error>?
    static func wait(_ operation: @escaping @MainActor @Sendable () async throws -> T) throws -> T {
        precondition(!Thread.isMainThread)
        let box = NFCBrowserResult<T>()
        let done = DispatchSemaphore(value: 0)
        Task { @MainActor in
            do { box.result = .success(try await operation()) }
            catch { box.result = .failure(error) }
            done.signal()
        }
        done.wait()
        return try box.result!.get()
    }
}
