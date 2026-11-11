import Foundation
import MoldSignKit

struct DemoDocumentSigner: DocumentSigning {
    let files: any DemoDocumentProviding
    func sign(_ item: SignItem, pin: String, reader: String, certificateSHA1: String,
              progress: @escaping @Sendable (SigningService.Step) -> Void) async throws -> URL {
        // Do not inspect the source URL, bytes, credential, certificate or reader.
        for step in [SigningService.Step.connecting, .signing, .writing] {
            progress(step)
            try await Task.sleep(for: .milliseconds(100))
        }
        return try files.output()
    }
}
