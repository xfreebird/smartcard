import Foundation

/// Owns asynchronous requests for one service lifetime. Invalidated results cannot authorize new work.
@MainActor
final class CancellableRequestScope {
    private var generation = UUID()
    private var cancellations: [UUID: () -> Void] = [:]

    func run<Value: Sendable>(fallback: Value, operation: @escaping @MainActor () async -> Value) async -> Value {
        guard !Task.isCancelled else { return fallback }
        let current = generation
        let id = UUID()
        let task = Task { @MainActor in await operation() }
        cancellations[id] = { task.cancel() }
        defer { cancellations[id] = nil }
        let value = await withTaskCancellationHandler {
            await task.value
        } onCancel: { task.cancel() }
        return current == generation && !Task.isCancelled ? value : fallback
    }

    func cancelAll() {
        generation = UUID()
        let callbacks = Array(cancellations.values)
        cancellations.removeAll()
        callbacks.forEach { $0() }
    }
}
