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
    func inspect(_ url: URL) async throws -> [Validator.Report]
    func inspect(_ url: URL, companions: [URL]) async throws -> [Validator.Report]
}
extension DocumentVerifying {
    func inspect(_ url: URL, companions: [URL]) async throws -> [Validator.Report] { try await inspect(url) }
    func inspect(_ url: URL) async throws -> [Validator.Report] { await verify(url) }
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
                                             expectedCertificateSHA1: certificateSHA1, appearance: item.stamp, progress: progress)
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
        (try? await inspect(url)) ?? []
    }

    func inspect(_ url: URL) async throws -> [Validator.Report] {
        try await inspect(url, companions: [])
    }

    func inspect(_ url: URL, companions: [URL]) async throws -> [Validator.Report] {
        let inputs = [url] + companions
        let scopes = inputs.filter { $0.startAccessingSecurityScopedResource() }
        defer { scopes.forEach { $0.stopAccessingSecurityScopedResource() } }
        try Task.checkCancellation()
        let reports = try await Task.detached {
            let data = try Data(contentsOf: url)
            let isPDF = url.pathExtension.lowercased() == "pdf"
            let initial = service.verify(data, isPDF: isPDF, detached: [:])
            guard !isPDF else { return initial }
            let names = Set(initial.flatMap(\.missingDetachedReferences))
            let files = DetachedDocumentAccess.companions(named: names, near: url, selected: companions)
            return service.verify(data, isPDF: false, detached: files)
        }.value
        try Task.checkCancellation()
        return reports
    }
}
