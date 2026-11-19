import SwiftUI
import UniformTypeIdentifiers

struct PublicCertificateExport: FileDocument {
    static var certificateType: UTType { UTType(filenameExtension: "cer") ?? .data }
    static var readableContentTypes: [UTType] { [certificateType] }
    let data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let bytes = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        data = bytes
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}
