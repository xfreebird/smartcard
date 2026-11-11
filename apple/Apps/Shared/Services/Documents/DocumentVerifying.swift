import Foundation
import MoldSignKit

protocol DocumentVerifying: Sendable {
    func verify(_ url: URL) async -> [Validator.Report]
    func inspect(_ url: URL) async throws -> [Validator.Report]
    func inspect(_ url: URL, companions: [URL]) async throws -> [Validator.Report]
}
extension DocumentVerifying {
    func inspect(_ url: URL, companions: [URL]) async throws -> [Validator.Report] { try await inspect(url) }
    func inspect(_ url: URL) async throws -> [Validator.Report] { await verify(url) }
}
