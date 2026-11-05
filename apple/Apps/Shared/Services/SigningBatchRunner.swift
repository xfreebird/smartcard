import Foundation

/// Serializes one user-authorized batch across suspension points. Items and context are value
/// snapshots supplied by the caller; a credential stays local to this invocation and is never cached.
@MainActor
final class SigningBatchRunner {
    enum Outcome: Equatable { case completed, cancelled, alreadyRunning, failed }
    private(set) var isRunning = false

    func run<Item, Context, Credential, Output>(
        items: [Item], context: Context,
        authorize: (Context, [Item]) async -> Credential?,
        sign: (Item, Context, Credential) async throws -> Output,
        didSign: (Item, Output, Credential) -> Void,
        didFail: (Item, Error) -> Void,
        shouldContinue: (Error) -> Bool = { _ in false }
    ) async -> Outcome {
        guard !isRunning else { return .alreadyRunning }
        isRunning = true
        defer { isRunning = false }
        guard let credential = await authorize(context, items) else { return .cancelled }
        for item in items {
            do {
                let output = try await sign(item, context, credential)
                didSign(item, output, credential)
            } catch {
                didFail(item, error)
                if shouldContinue(error) { continue }
                return .failed
            }
        }
        return .completed
    }
}
