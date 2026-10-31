import Foundation
import MoldSignKit

/// Signs and writes a single document; no UI, queue management, or PIN retention.
final class DocumentSigner: DocumentSigning {
    private let service: SigningService
    init(service: SigningService) { self.service = service }
    /// One file: PAdES-T for PDF, XAdES (detached) otherwise; written next to the original.
    func sign(_ item: SignItem, pin: String, reader: String, certificateSHA1: String,
                             progress: @escaping (SigningService.Step) -> Void) throws -> URL {
        let input = item.url
        let signed: Data
        if let xades = item.format.xades {
            signed = try service.signXAdES(files: [input], format: xades, type: .detached, pin: pin, reader: reader,
                                           expectedCertificateSHA1: certificateSHA1, progress: progress)
        } else {
            signed = try service.signPDF(try Data(contentsOf: input), pin: pin, reader: reader,
                                         expectedCertificateSHA1: certificateSHA1, progress: progress)
        }
        progress(.writing)
        let preferred = SigningService.outputURL(for: input, pathExtension: item.format.outputExtension)
        do {
            try signed.write(to: preferred, options: .withoutOverwriting)
            return preferred
        } catch {
            // Read-only folder, or a Flatpak document-portal file whose folder is not exposed:
            // fall back to ~/Documents/MoldSign (granted by --filesystem=xdg-documents).
            // TODO(LNX-13): offer a GtkFileDialog save instead when the fallback also fails.
            let folder = URL(fileURLWithPath: documentsDir).appendingPathComponent("MoldSign")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let fallback = SigningService.outputURL(for: folder.appendingPathComponent(input.lastPathComponent),
                                                    pathExtension: item.format.outputExtension)
            try signed.write(to: fallback, options: .withoutOverwriting)
            return fallback
        }
    }

}
