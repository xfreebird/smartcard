import Foundation
import MoldSignKit

/// Narrow app ports let a scenario replace card reads, signing or verification independently.
protocol CertificateReading: Sendable {
    func readCertificate(reader: String) async throws -> SigningService.CertificateSummary
}
protocol DocumentSigning: Sendable {
    func sign(_ item: SignItem, pin: String, reader: String, certificateSHA1: String,
              progress: @escaping @Sendable (SigningService.Step) -> Void) async throws -> URL
}
protocol DocumentVerifying: Sendable {
    func verify(_ url: URL) async -> [Validator.Report]
}

struct CoreCertificateReader: CertificateReading {
    let service: SigningService
    func readCertificate(reader: String) async throws -> SigningService.CertificateSummary {
        try await Task.detached { try service.readCertificate(reader: reader) }.value
    }
}

/// Owns security-scoped file access, core dispatch and output policy; UI state never writes files.
struct CoreDocumentSigner: DocumentSigning {
    let service: SigningService
    func sign(_ item: SignItem, pin: String, reader: String, certificateSHA1: String,
              progress: @escaping @Sendable (SigningService.Step) -> Void) async throws -> URL {
        let scoped = item.url.startAccessingSecurityScopedResource()
        defer { if scoped { item.url.stopAccessingSecurityScopedResource() } }
        return try await Task.detached {
            let output = Self.outputURL(for: item.url, format: item.format)
            let signed: Data
            if let format = item.format.xades {
                signed = try service.signXAdES(files: [item.url], format: format, pin: pin, reader: reader,
                                               expectedCertificateSHA1: certificateSHA1, progress: progress)
            } else {
                signed = try service.signPDF(Data(contentsOf: item.url), pin: pin, reader: reader,
                                             expectedCertificateSHA1: certificateSHA1, progress: progress)
            }
            progress(.writing)
            try signed.write(to: output, options: .withoutOverwriting)
            return output
        }.value
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

struct CoreDocumentVerifier: DocumentVerifying {
    let service: SigningService
    func verify(_ url: URL) async -> [Validator.Report] {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        return await Task.detached {
            guard let data = try? Data(contentsOf: url) else { return [] }
            let isPDF = url.pathExtension.lowercased() == "pdf"
            return service.verify(data, isPDF: isPDF,
                                  detached: isPDF ? [:] : Self.detachedDocuments(for: data, near: url))
        }.value
    }

    private static func detachedDocuments(for xml: Data, near url: URL) -> [String: Data] {
        var files: [String: Data] = [:]
        let text = String(decoding: xml, as: UTF8.self)
        var start = text.startIndex
        while let range = text.range(of: "URI=\"file:/", range: start..<text.endIndex),
              let end = text[range.upperBound...].firstIndex(of: "\"") {
            let name = String(text[range.upperBound..<end])
            // Detached signatures may only refer to neighbouring basenames, never arbitrary paths.
            if URL(filePath: name).lastPathComponent == name {
                files[name] = try? Data(contentsOf: url.deletingLastPathComponent().appendingPathComponent(name))
            }
            start = end
        }
        return files
    }
}
