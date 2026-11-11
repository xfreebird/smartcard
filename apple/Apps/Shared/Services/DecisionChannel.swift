import Foundation

/// One user decision at a time. Installation precedes presentation; cancellation cannot resolve a newer prompt.
@MainActor
final class DecisionChannel<Value: Sendable> {
    private var pending: (id: UUID, continuation: CheckedContinuation<Value, Never>, dismiss: () -> Void)?
    var isPending: Bool { pending != nil }

    func request(fallback: Value, present: () -> Void, dismiss: @escaping () -> Void = {}) async -> Value {
        guard pending == nil, !Task.isCancelled else { return fallback }
        let id = UUID()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                guard !Task.isCancelled else { continuation.resume(returning: fallback); return }
                pending = (id, continuation, dismiss)
                present()
            }
        } onCancel: {
            Task { @MainActor [weak self] in self?.resolve(fallback, matching: id) }
        }
    }

    func resolve(_ value: Value) { resolve(value, matching: pending?.id) }

    private func resolve(_ value: Value, matching id: UUID?) {
        guard let current = pending, current.id == id else { return }
        pending = nil
        current.dismiss()
        current.continuation.resume(returning: value)
    }
}
