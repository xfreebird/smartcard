import XCTest
import UniformTypeIdentifiers
@testable import AppBatch

final class DroppedDocumentLoaderTests: XCTestCase {
    func testDocumentRepresentationIsCopiedBeforeProviderURLExpires() async throws {
        let source = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".pdf")
        let bytes = Data("%PDF-1.7\nfixture".utf8)
        try bytes.write(to: source)
        let provider = NSItemProvider()
        provider.suggestedName = "signed-sample.pdf"
        provider.registerFileRepresentation(forTypeIdentifier: UTType.pdf.identifier, fileOptions: [], visibility: .all) { completion in
            completion(source, false, nil)
            try? FileManager.default.removeItem(at: source)
            return nil
        }
        let urls = await DroppedDocumentLoader.load([provider])
        XCTAssertEqual(urls.count, 1)
        let copy = try XCTUnwrap(urls.first)
        defer { try? FileManager.default.removeItem(at: copy.deletingLastPathComponent()) }
        XCTAssertEqual(copy.lastPathComponent, "signed-sample.pdf")
        XCTAssertEqual(try Data(contentsOf: copy), bytes)
        XCTAssertNotEqual(copy, source)
    }

    func testFileURLRepresentationLoadsEveryDocument() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let providers = try ["first.pdf", "second.xml"].map { name -> NSItemProvider in
            let url = folder.appendingPathComponent(name)
            try Data(name.utf8).write(to: url)
            return NSItemProvider(item: url as NSURL, typeIdentifier: UTType.fileURL.identifier)
        }
        let copies = await DroppedDocumentLoader.load(providers)
        defer { for copy in copies { try? FileManager.default.removeItem(at: copy.deletingLastPathComponent()) } }
        XCTAssertEqual(copies.count, 2)
        XCTAssertEqual(Set(copies.map(\.lastPathComponent)), Set(["first.pdf", "second.xml"]))
    }
}
