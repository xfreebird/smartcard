import Foundation
import MoldSignKit

/// Owns security-scoped file access, core dispatch and output policy; UI state never writes files.
struct CoreDocumentSigner: DocumentSigning {
    let service: SigningService
    func sign(_ item: SignItem, pin: String, reader: String, certificateSHA1: String,
              progress: @escaping @Sendable (SigningService.Step) -> Void) async throws -> URL {
        let scoped = item.url.startAccessingSecurityScopedResource()
        defer { if scoped { item.url.stopAccessingSecurityScopedResource() } }
        try Task.checkCancellation()
        let operation = Task.detached {
            try Task.checkCancellation()
            let output = Self.outputURL(for: item.url, format: item.format)
            let signed: Data
            if let format = item.format.xades {
                signed = try service.signXAdES(files: [item.url], format: format, pin: pin, reader: reader,
                                               expectedCertificateSHA1: certificateSHA1, progress: progress)
            } else {
                signed = try service.signPDF(Data(contentsOf: item.url), pin: pin, reader: reader,
                                             expectedCertificateSHA1: certificateSHA1, appearance: item.stamp, progress: progress)
            }
            progress(.writing)
            try Task.checkCancellation()
            try signed.write(to: output, options: .withoutOverwriting)
            return output
        }
        return try await withTaskCancellationHandler {
            try await operation.value
        } onCancel: { operation.cancel() }
    }

    private static func outputURL(for input: URL, format: SignFormat) -> URL {
        let ext = format == .padesT ? "pdf" : "xml"
        #if os(macOS) && !APP_STORE
        return SigningService.outputURL(for: input, pathExtension: ext)
        #else
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return SigningService.outputURL(for: documents.appendingPathComponent(input.lastPathComponent), pathExtension: ext)
        #endif
    }
}
