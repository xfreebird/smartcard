import CAdwaita
import Foundation
import XCTest
@testable import MoldSignGnome

/// The ID-card face and the placeholder cards, painted into off-screen cairo surfaces (no display needed).
final class CardArtTests: GnomeTestCase {
    private func render(width: Int32 = CardArt.large.width, height: Int32 = CardArt.large.height,
                        _ draw: (OpaquePointer) -> Void) -> (opaque: Int, distinct: Int) {
        let surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, width, height)!
        defer { cairo_surface_destroy(surface) }
        let cr = cairo_create(surface)!
        draw(cr)
        cairo_destroy(cr)
        cairo_surface_flush(surface)
        let stride = Int(cairo_image_surface_get_stride(surface))
        let data = cairo_image_surface_get_data(surface)!
        var opaque = 0
        var colors = Set<UInt32>()
        for y in 0..<Int(height) {
            let row = UnsafeRawPointer(data + y * stride).assumingMemoryBound(to: UInt32.self)
            for x in 0..<Int(width) {
                let pixel = row[x]
                if pixel >> 24 != 0 { opaque += 1 }
                colors.insert(pixel)
            }
        }
        return (opaque, colors.count)
    }

    private func face(_ state: CardArt.Face.State, values: Bool = true, chosen: Bool = false, showsReader: Bool = true) -> CardArt.Face {
        CardArt.Face(surname: values ? "MÎNDRU" : nil, givenNames: values ? "ȘTEFAN ALEXANDRU CONSTANTIN" : nil,
                     validUntil: values ? "14 01 2031" : nil, issuer: values ? "MDQSign" : nil, state: state,
                     reader: "Bit4id miniLector POCKET EVO 00 00", hueShift: CardArt.hueShift(sha1Hex: "ff00", fallback: ""),
                     showsReader: showsReader, reservesDisclosure: true, chosen: chosen)
    }

    func testEveryCardStatePaintsAFullCardFace() {
        let font = pango_font_description_from_string("Cantarell 11")
        defer { pango_font_description_free(font) }
        var results: [(Int, Int)] = []
        for state: CardArt.Face.State in [.ready, .reading, .busy, .problem("Cardul nu răspunde")] {
            results.append(render { CardArt.drawIDCard($0, width: 340, height: 210, face: face(state, values: state != .reading), font: font) })
        }
        results.append(render { CardArt.drawIDCard($0, width: 340, height: 210, face: face(.ready, chosen: true), font: nil) })
        results.append(render(width: CardArt.compact.width, height: CardArt.compact.height) {
            CardArt.drawIDCard($0, width: 260, height: 161, face: face(.ready, showsReader: false), font: font)
        })
        for (opaque, distinct) in results {
            XCTAssertGreaterThan(opaque, 340 * 210 / 2, "The face covers the card area")
            XCTAssertGreaterThan(distinct, 50, "Guilloche, chip, text and status strip are drawn")
        }
    }

    func testPlaceholdersDrawTheirGlyphs() {
        let fg = CardArt.RGB(0x202020), danger = CardArt.RGB(0xC62828)
        for kind: CardArt.Placeholder in [.insertCard, .noReader, .error] {
            for scale in [1.0, 1.5] {
                let (opaque, distinct) = render {
                    CardArt.drawPlaceholder($0, kind, width: 340, height: 210, fg: fg, danger: danger, glyphCenterY: 90, glyphScale: scale)
                }
                XCTAssertGreaterThan(opaque, 1000, "\(kind)")
                XCTAssertGreaterThan(distinct, 3, "\(kind)")
            }
        }
        let (chip, _) = render(width: 60, height: 50) { CardArt.drawChip($0, x: 5, y: 5, width: 50, height: 40) }
        XCTAssertGreaterThan(chip, 1500)
    }

    func testHueShiftIsStableAndBounded() {
        XCTAssertEqual(CardArt.hueShift(sha1Hex: "00aa", fallback: "x"), -20)
        XCTAssertEqual(CardArt.hueShift(sha1Hex: "ffaa", fallback: "x"), 20)
        let fromReader = CardArt.hueShift(sha1Hex: nil, fallback: "Reader A")
        XCTAssertEqual(fromReader, CardArt.hueShift(sha1Hex: "z", fallback: "Reader A"))
        XCTAssertTrue((-20...20).contains(fromReader))
        let grey = CardArt.RGB(0x808080)
        XCTAssertEqual(grey.rotated(90).r, grey.r, accuracy: 1e-9)
        for color in [CardArt.RGB(0xFF2010), CardArt.RGB(0x10FF20), CardArt.RGB(0x1020FF), CardArt.RGB(0xF0D0E0)] {
            let back = color.rotated(120).rotated(240)
            XCTAssertEqual(back.r, color.r, accuracy: 1e-6)
            XCTAssertEqual(back.g, color.g, accuracy: 1e-6)
            XCTAssertEqual(back.b, color.b, accuracy: 1e-6)
        }
        XCTAssertEqual(CardArt.hsl(-120, 1, 0.5).b, 1, accuracy: 1e-9)
    }
}
