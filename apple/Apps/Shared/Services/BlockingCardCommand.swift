import Foundation

/// A single APDU result. Cancellation, timeout and a late callback can complete it only once.
final class BlockingCardCommand: @unchecked Sendable {
    private let lock = NSLock()
    private let signal = DispatchSemaphore(value: 0)
    private var result: Result<Data, Error>?

    func complete(_ value: Result<Data, Error>) {
        lock.lock()
        guard result == nil else { lock.unlock(); return }
        result = value
        lock.unlock()
        signal.signal()
    }

    func wait(until deadline: DispatchTime, timeoutError: Error) throws -> Data {
        if signal.wait(timeout: deadline) == .timedOut { complete(.failure(timeoutError)) }
        lock.lock()
        let value = result!
        lock.unlock()
        return try value.get()
    }
}
