import XCTest
@testable import MoldSignKit

final class PDFStampTests: XCTestCase {
    func testCornerResizeKeepsOppositeCornerAndProportionsInsidePage() throws {
        let start = PDFStampPlacement(x: 0.2, y: 0.3, width: 0.4, height: 0.16)
        for corner in 0..<4 {
            for delta in [-100.0, -0.05, 0.05, 100.0] {
                let resized = start.resized(corner: corner, dx: delta, dy: delta)
                XCTAssertNoThrow(try resized.validate())
                XCTAssertEqual(resized.height / resized.width, 0.4, accuracy: 0.000001)
                XCTAssertEqual(corner % 2 == 1 ? resized.x : resized.x+resized.width,
                               corner % 2 == 1 ? start.x : start.x+start.width, accuracy: 0.000001)
                XCTAssertEqual(corner >= 2 ? resized.y : resized.y+resized.height,
                               corner >= 2 ? start.y : start.y+start.height, accuracy: 0.000001)
            }
        }
    }

    private let catalog = "<< /Type /Catalog /Pages 1 0 R >>"
    // Page order deliberately differs from object order; crop/rotation are inherited.
    private let pdf = """
    1 0 obj << /Type /Pages /Kids [3 0 R 2 0 R] /Count 2 /MediaBox [0 0 600 800] /CropBox [20 30 520 730] /Rotate 90 >> endobj
    2 0 obj << /Type /Page /Parent 1 0 R /Rotate 0 /Annots [] >> endobj
    3 0 obj << /Type /Page /Parent 1 0 R /Annots 7 0 R /Private (keep \\(text\\) /Annots [999 0 R]) >> endobj
    7 0 obj [8 0 R] endobj
    8 0 obj << /Type /Annot /Subtype /Link /Rect [0 0 10 10] >> endobj
    """

    func testPageTreeOrderAndInheritedGeometry() throws {
        let pages = try StampPDF.pages(pdf, catalog: catalog)
        XCTAssertEqual(pages.map(\.number), [3, 2])
        XCTAssertEqual(pages.map(\.rotation), [90, 0])
        XCTAssertEqual(pages[0].box, [20, 30, 520, 730])
    }

    func testAllPagesHasOneSignatureWidgetAndLinkBackFromCopies() throws {
        let (_, chunks, _) = try StampPDF.appearance(text: pdf, catalog: catalog, field: 12, signature: 10,
            first: 13, name: "Signature1", placement: .init(allPages: true, x: 0.1, y: 0.2, width: 0.4, height: 0.1),
            holder: "Ștefan Țurcanu Иванов", date: Date(timeIntervalSince1970: 0))
        let forms = try chunks.filter { $0.contains("/Subtype /Form") }.map { chunk in
            XCTAssertTrue(chunk.contains("/Filter /ASCIIHexDecode"))
            let start = try XCTUnwrap(chunk.range(of: "stream\n")?.upperBound)
            let end = try XCTUnwrap(chunk.range(of: ">\nendstream", range: start..<chunk.endIndex)?.lowerBound)
            return String(decoding: Data(hex: String(chunk[start..<end])), as: UTF8.self)
        }.joined()
        XCTAssertFalse(forms.contains(" re f"), "The stamp must not paint an opaque background")
        XCTAssertTrue(forms.contains("0.5 10 174 21 re S"))
        let update = chunks.joined()
        XCTAssertEqual(update.components(separatedBy: "/Subtype /Widget").count - 1, 1)
        XCTAssertEqual(update.components(separatedBy: "/Subtype /Stamp").count - 1, 1)
        XCTAssertTrue(update.contains("/Dest [3 0 R /FitR 120.00000 100.00000 170.00000 380.00000]"))
        XCTAssertTrue(update.contains("/Annots [8 0 R "))
        XCTAssertTrue(update.contains("/Private (keep \\(text\\) /Annots [999 0 R])"))
        XCTAssertTrue(update.contains("/Matrix [0 1 -1 0 96 0]"))
    }

    func testOnePageDoesNotTouchOtherPages() throws {
        let (field, chunks, _) = try StampPDF.appearance(text: pdf, catalog: catalog, field: 12, signature: 10,
            first: 13, name: "Signature1", placement: .init(page: 1), holder: "Ion Popescu", date: Date())
        XCTAssertTrue(field.contains("/V 10 0 R"))
        XCTAssertTrue(chunks.contains { $0.hasPrefix("2 0 obj") })
        XCTAssertFalse(chunks.contains { $0.hasPrefix("3 0 obj") })
        XCTAssertFalse(chunks.joined().contains("/Subtype /Stamp"))
    }

    func testInvalidPlacementAndUnsupportedTreesFailBeforeSignature() {
        for placement in [PDFStampPlacement(page: 8), .init(x: -.infinity), .init(x: 0.9, width: 0.4)] {
            XCTAssertThrowsError(try StampPDF.appearance(text: pdf, catalog: catalog, field: 12, signature: 10,
                first: 13, name: "Signature1", placement: placement, holder: "Ion", date: Date()))
        }
        XCTAssertThrowsError(try StampPDF.pages("1 0 obj << /Type /Pages /Kids [1 0 R] >> endobj", catalog: catalog))
        XCTAssertThrowsError(try StampPDF.appearance(text: pdf, catalog: "<< /Pages 1 0 R /Perms <<>> >>", field: 12,
            signature: 10, first: 13, name: "Signature1", placement: .init(), holder: "Ion", date: Date()))
    }
    func testBridgePreviewIsOptionalAndReusedOnlyWithinSiteCardBatch() throws {
        let server = MoldSignServer()
        let data = try Fixtures.data("unsigned.pdf")
        let request = BridgeRequest(origin: "https://msign.gov.md", operation: .signData, documentName: "document.pdf",
                                    format: "PAdES-T", pinIncluded: false)
        XCTAssertNil(try server.stampPlacement(request, data, batch: "batch"))
        var prompts = 0
        server.previewPDF = { _, _ in prompts += 1; return .proceed(.init()) }
        XCTAssertNotNil(try server.stampPlacement(request, data, batch: "batch"))
        XCTAssertNotNil(try server.stampPlacement(request, data, batch: "batch"))
        XCTAssertEqual(prompts, 1)
        let other = BridgeRequest(origin: "https://other.gov.md", operation: .signData, documentName: "document.pdf",
                                  format: "PAdES-T", pinIncluded: false)
        _ = try server.stampPlacement(other, data, batch: "batch")
        XCTAssertEqual(prompts, 2)
        server.previewPDF = { _, _ in .cancel }
        XCTAssertThrowsError(try server.stampPlacement(request, data, batch: "another"))
    }

    func testDocumentBindingRejectsChangedBytes() throws {
        let data = Data("original".utf8)
        let placement = PDFStampPlacement().bound(to: data)
        XCTAssertNoThrow(try placement.validate(document: data))
        XCTAssertThrowsError(try placement.validate(document: Data("changed".utf8)))
    }

}
