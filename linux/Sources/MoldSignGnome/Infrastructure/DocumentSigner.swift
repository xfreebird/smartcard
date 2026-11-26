import Foundation
import MoldSignKit

/// Produces the signature bytes for one document (the card, through the core).
protocol SignatureProducing {
    func signature(for item: SignItem, pin: String, reader: String, certificateSHA1: String,
                   progress: @escaping (SigningService.Step) -> Void) throws -> Data
}

/// PAdES-T for PDF, detached XAdES otherwise.
struct CardSignatureProducer: SignatureProducing {
    let service: SigningService
    func signature(for item: SignItem, pin: String, reader: String, certificateSHA1: String,
                   progress: @escaping (SigningService.Step) -> Void) throws -> Data {
        if let xades = item.format.xades {
            return try service.signXAdES(files: [item.url], format: xades, type: .detached, pin: pin, reader: reader,
                                         expectedCertificateSHA1: certificateSHA1, progress: progress)
        }
        return try service.signPDF(try Data(contentsOf: item.url), pin: pin, reader: reader,
                                   expectedCertificateSHA1: certificateSHA1, appearance: item.stamp, progress: progress)
    }
}

/// Signs and writes a single document; no UI, queue management, or PIN retention.
final class DocumentSigner: DocumentSigning {
    private let producer: any SignatureProducing
    private let fallbackFolder: () -> URL

    convenience init(service: SigningService) { self.init(producer: CardSignatureProducer(service: service)) }

    /// `fallbackFolder`: where outputs go when the original's folder is not writable (`~/Documents/MoldSign`).
    init(producer: any SignatureProducing,
         fallbackFolder: @escaping () -> URL = { URL(fileURLWithPath: documentsDir).appendingPathComponent("MoldSign") }) {
        self.producer = producer
        self.fallbackFolder = fallbackFolder
    }

    /// One file, written next to the original.
    func sign(_ item: SignItem, pin: String, reader: String, certificateSHA1: String,
                             progress: @escaping (SigningService.Step) -> Void) throws -> URL {
        let input = item.url
        let signed = try producer.signature(for: item, pin: pin, reader: reader, certificateSHA1: certificateSHA1,
                                            progress: progress)
        progress(.writing)
        let preferred = SigningService.outputURL(for: input, pathExtension: item.format.outputExtension)
        do {
            try signed.write(to: preferred, options: .withoutOverwriting)
            return preferred
        } catch {
            // Read-only folder, or a Flatpak document-portal file whose folder is not exposed:
            // fall back to ~/Documents/MoldSign (granted by --filesystem=xdg-documents).
            // TODO(LNX-13): offer a GtkFileDialog save instead when the fallback also fails.
            let folder = fallbackFolder()
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let fallback = SigningService.outputURL(for: folder.appendingPathComponent(input.lastPathComponent),
                                                    pathExtension: item.format.outputExtension)
            try signed.write(to: fallback, options: .withoutOverwriting)
            return fallback
        }
    }

}
