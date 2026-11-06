import Foundation

/// Coordinates are fractions of the displayed CropBox, measured from its top-left.
/// The selection belongs to one input document; page is zero-based. Nil means invisible signing.
public struct PDFStampPlacement: Sendable, Equatable {
    public var documentSHA256: String?
    public var page: Int
    public var allPages: Bool
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public init(page: Int = 0, allPages: Bool = false, x: Double = 0.06, y: Double = 0.72,
                width: Double = 0.40, height: Double = 0.113) {
        self.page = page; self.allPages = allPages; self.x = x; self.y = y
        self.width = width; self.height = height
    }
    /// Corner order: top-left, top-right, bottom-left, bottom-right. Deltas use page fractions.
    public func resized(corner: Int, dx: Double, dy: Double) -> Self {
        guard (0..<4).contains(corner), dx.isFinite, dy.isFinite, width > 0, height > 0 else { return self }
        let right = corner % 2 == 1, bottom = corner >= 2, ratio = height / width
        let horizontal = (right ? dx : -dx), vertical = (bottom ? dy : -dy) / ratio
        let delta = abs(horizontal) >= abs(vertical) ? horizontal : vertical
        let limit = min(right ? 1-x : x+width, (bottom ? 1-y : y+height) / ratio)
        let w = min(limit, max(min(0.1, limit), width + delta)), h = w * ratio
        var copy = self
        copy.x = right ? x : x+width-w; copy.y = bottom ? y : y+height-h
        copy.width = w; copy.height = h
        return copy
    }
    public func bound(to document: Data) -> Self {
        var copy = self; copy.documentSHA256 = document.sha256().hexString; return copy
    }
    func validate(document: Data) throws {
        if let documentSHA256, documentSHA256 != document.sha256().hexString {
            throw CardError.signFailed("The PDF changed after stamp placement. Open the preview again")
        }
    }
    func validate() throws {
        guard page >= 0, [x, y, width, height].allSatisfy(\.isFinite), x >= 0, y >= 0,
              width > 0, height > 0, x + width <= 1.000001, y + height <= 1.000001 else {
            throw CardError.signFailed("The signature stamp must fit inside the page")
        }
    }
}

public enum PDFStampDecision: Sendable {
    case cancel
    case proceed(PDFStampPlacement?)
}

/// Small syntax reader for the uncompressed PDFs supported by the incremental signer.
/// Values are kept verbatim so updating /Annots never changes unrelated page entries.
/// Compressed page dictionaries, encryption, malformed trees and nonzero generations fail closed.
enum StampPDF {
    static func tokens(_ s: String) -> [String] {
        let a = Array(s); var i = 0; var out: [String] = []
        while i < a.count {
            if a[i].isWhitespace { i += 1; continue }
            if a[i] == "%" { while i < a.count && a[i] != "\n" && a[i] != "\r" { i += 1 }; continue }
            let start = i
            if a[i] == "(" {
                var depth = 1; i += 1
                while i < a.count && depth > 0 {
                    if a[i] == "\\" { i += min(2, a.count - i); continue }
                    if a[i] == "(" { depth += 1 }; if a[i] == ")" { depth -= 1 }; i += 1
                }
            } else if a[i] == "<" && i + 1 < a.count && a[i + 1] != "<" {
                i += 1; while i < a.count && a[i] != ">" { i += 1 }; if i < a.count { i += 1 }
            } else if i + 1 < a.count && ["<<", ">>"].contains(String(a[i...i+1])) { i += 2
            } else if "[]<>".contains(a[i]) { i += 1
            } else {
                i += 1
                while i < a.count && !a[i].isWhitespace && !"/[]<>()%".contains(a[i]) { i += 1 }
            }
            out.append(String(a[start..<i]))
        }
        return out
    }
    static func entries(_ dict: String) throws -> [(String, String)] {
        let t = tokens(dict); var i = 1; var out: [(String, String)] = []
        guard t.first == "<<" else { throw fail() }
        while i < t.count && t[i] != ">>" {
            let key = t[i]; i += 1; let start = i
            guard key.hasPrefix("/"), !key.contains("#"), !out.contains(where: { $0.0 == key }), i < t.count else { throw fail() }
            if t[i] == "<<" || t[i] == "[" {
                var depth = 0
                repeat {
                    if t[i] == "<<" || t[i] == "[" { depth += 1 }
                    if t[i] == ">>" || t[i] == "]" { depth -= 1 }
                    i += 1
                } while i < t.count && depth > 0
                guard depth == 0 else { throw fail() }
            } else if i + 2 < t.count && Int(t[i]) != nil && Int(t[i+1]) != nil && t[i+2] == "R" { i += 3
            } else { i += 1 }
            out.append((key, t[start..<i].joined(separator: " ")))
        }
        guard i == t.count - 1, t.last == ">>" else { throw fail() }
        return out
    }
    static func value(_ dict: String, _ key: String) throws -> String? {
        let values = try entries(dict).filter { $0.0 == key }
        guard values.count <= 1 else { throw fail() }
        return values.first?.1
    }
    static func set(_ dict: String, _ key: String, _ value: String) throws -> String {
        var e = try entries(dict).filter { $0.0 != key }; e.append((key, value))
        return "<< " + e.map { "\($0.0) \($0.1)" }.joined(separator: " ") + " >>"
    }
    static func ref(_ value: String) throws -> Int {
        let t = tokens(value)
        guard t.count == 3, t[1] == "0", t[2] == "R", let n = Int(t[0]), n > 0 else { throw fail() }
        return n
    }
    static func refs(_ value: String) throws -> [Int] {
        let t = tokens(value); guard t.first == "[", t.last == "]", (t.count - 2) % 3 == 0 else { throw fail() }
        return try stride(from: 1, to: t.count - 1, by: 3).map { try ref(t[$0..<$0+3].joined(separator: " ")) }
    }
    static func object(_ text: String, _ n: Int) throws -> String {
        let re = try NSRegularExpression(pattern: "(?<!\\d)\(n)\\s+0\\s+obj\\b")
        guard let m = re.matches(in: text, range: NSRange(text.startIndex..., in: text)).last,
              let r = Range(m.range, in: text), let end = text.range(of: "endobj", range: r.upperBound..<text.endIndex) else { throw fail() }
        return String(text[r.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    struct Page {
        let number: Int
        let dict: String
        let box: [Double]
        let rotation: Int
    }
    static func pages(_ text: String, catalog: String) throws -> [Page] {
        guard !text.contains("/Encrypt"), let root = try value(catalog, "/Pages") else { throw fail() }
        var visited = Set<Int>(); var result: [Page] = []
        func walk(_ n: Int, _ inherited: [String: String], _ depth: Int) throws {
            guard depth < 100, visited.insert(n).inserted else { throw fail() }
            let dict = try object(text, n); var props = inherited
            for key in ["/MediaBox", "/CropBox", "/Rotate", "/UserUnit"] { if let v = try value(dict, key) { props[key] = v } }
            if try value(dict, "/Type") == "/Pages" {
                guard let kids = try value(dict, "/Kids") else { throw fail() }
                for child in try refs(kids) { try walk(child, props, depth + 1) }
            } else {
                guard try value(dict, "/Type") == "/Page", var box = props["/CropBox"] ?? props["/MediaBox"] else { throw fail() }
                if !box.hasPrefix("[") { box = try object(text, ref(box)) }
                func rectangle(_ input: String) throws -> [Double] {
                    let raw: String
                    if input.hasPrefix("[") { raw = input } else { raw = try object(text, ref(input)) }
                    let values = tokens(raw)
                    guard values.count == 6, values.first == "[", values.last == "]" else { throw fail() }
                    let parsed = values.dropFirst().dropLast().compactMap(Double.init)
                    guard parsed.count == 4, parsed.allSatisfy(\.isFinite), parsed[2] > parsed[0], parsed[3] > parsed[1] else { throw fail() }
                    return parsed
                }
                var numbers = try rectangle(box)
                if let media = props["/MediaBox"] {
                    let bounds = try rectangle(media)
                    numbers = [max(numbers[0], bounds[0]), max(numbers[1], bounds[1]), min(numbers[2], bounds[2]), min(numbers[3], bounds[3])]
                }
                let rotation = Int(props["/Rotate"] ?? "0") ?? -1
                guard numbers[2] > numbers[0], numbers[3] > numbers[1], rotation % 90 == 0, Double(props["/UserUnit"] ?? "1") == 1 else { throw fail() }
                result.append(Page(number: n, dict: dict, box: numbers, rotation: (rotation % 360 + 360) % 360))
            }
        }
        try walk(ref(root), [:], 0)
        guard !result.isEmpty else { throw fail() }; return result
    }
    static func canApply(_ placement: PDFStampPlacement, to data: Data) -> Bool {
        guard let text = String(data: data, encoding: .isoLatin1),
              let re = try? NSRegularExpression(pattern: #"/Root\s+(\d+)\s+0\s+R\b"#),
              let match = re.matches(in: text, range: NSRange(text.startIndex..., in: text)).last,
              let range = Range(match.range(at: 1), in: text), let root = Int(text[range]),
              let catalog = try? object(text, root), let pages = try? pages(text, catalog: catalog) else { return false }
        return pages.indices.contains(placement.page)
    }
    static func fail() -> CardError { .signFailed("This PDF cannot be stamped safely (unsupported page structure)") }
    private static func resource(_ name: String, _ ext: String) throws -> Data {
        #if os(Linux)
        for folder in [Bundle.main.bundleURL.appendingPathComponent("PDFStamp"),
                       Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("share/moldsign/PDFStamp"),
                       URL(fileURLWithPath: "/usr/share/moldsign/PDFStamp"),
                       URL(fileURLWithPath: "/app/share/moldsign/PDFStamp")] {
            let url = folder.appendingPathComponent(name).appendingPathExtension(ext)
            if FileManager.default.fileExists(atPath: url.path) { return try Data(contentsOf: url) }
        }
        #endif
        guard let url = Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "PDFStamp") else {
            throw CardError.signFailed("The signature font is missing")
        }
        return try Data(contentsOf: url)
    }
    static func num(_ n: Double) -> String { String(format: "%.5f", locale: Locale(identifier: "en_US_POSIX"), n) }
    static func stream(_ data: Data, extra: String = "") -> String {
        let hex = data.hexString + ">"
        return "<< /Length \(hex.utf8.count) /Filter /ASCIIHexDecode \(extra) >>\nstream\n\(hex)\nendstream"
    }

    /// One signature widget. Other pages carry stamp annotations with GoTo links to it.
    static func appearance(text: String, catalog: String, field: Int, signature: Int, first: Int,
                           name: String, placement: PDFStampPlacement, holder: String, date: Date) throws -> (String, [String], Int) {
        try placement.validate()
        if try value(catalog, "/Perms") != nil { throw CardError.signFailed("A certified PDF cannot receive additional stamps") }
        if let acro = try value(catalog, "/AcroForm") { _ = try ref(acro) }
        let pages = try pages(text, catalog: catalog)
        guard pages.indices.contains(placement.page) else { throw fail() }
        let primary = pages[placement.page]
        let selected = [primary] + (placement.allPages ? pages.filter { $0.number != primary.number } : [])
        let base = first; var next = first + 5
        let metrics = String(decoding: try resource("metrics", "txt"), as: UTF8.self).split(separator: "\n").reduce(into: [UInt32: (Int, Int)]()) { m, row in
            let v = row.split(separator: " ").compactMap { Int($0) }; if v.count == 3 { m[UInt32(v[0])] = (v[1], v[2]) }
        }
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.dateFormat = "yyyy.MM.dd HH:mm:ss z"
        let lines = ["Digitally signed by \(holder)", "Date: \(formatter.string(from: date))", "Reason: MoldSign Signature", "Location: Moldova", "MOLDOVA EUROPEANĂ", "Signed with eSemnBun"]
        var used: [Int: (UInt32, Int)] = [:]; var content = "q 0.65 G 0.5 w 0.5 10 174 21 re S 0 g\n"
        for (index, line) in lines.enumerated() {
            var hex = ""; var width = 0
            for scalar in line.unicodeScalars {
                guard let (gid, advance) = metrics[scalar.value] else { throw CardError.signFailed("The signature font cannot display a character in the signer name") }
                used[gid] = (scalar.value, advance); hex += String(format: "%04X", gid); width += advance
            }
            let size = min(index == 5 ? 7.0 : 13.0, 228000.0 / Double(max(width, 1)))
            content += "BT /F \(num(size)) Tf 1 0 0 1 \(index == 4 ? 5 : 0) \([82, 67, 52, 37, 16, 2][index]) Tm <\(hex)> Tj ET\n"
        }
        content += "Q"
        let mappings = used.sorted { $0.key < $1.key }.map { gid, value in
            let utf16 = String(UnicodeScalar(value.0)!).utf16.map { String(format: "%04X", $0) }.joined()
            return "<\(String(format: "%04X", gid))> <\(utf16)>"
        }
        let sections = stride(from: 0, to: mappings.count, by: 100).map { start in
            let group = mappings[start..<min(start+100, mappings.count)]
            return "\(group.count) beginbfchar\n" + group.joined(separator: "\n") + "\nendbfchar\n"
        }.joined()
        let cmap = "/CIDInit /ProcSet findresource begin 12 dict begin begincmap /CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def /CMapName /StampUnicode def /CMapType 2 def 1 begincodespacerange <0000> <FFFF> endcodespacerange\n" + sections + "endcmap CMapName currentdict /CMap defineresource pop end end"
        let font = try resource("LiberationSerif-Regular", "ttf")
        func obj(_ n: Int, _ body: String) -> String { "\(n) 0 obj\n\(body)\nendobj\n" }
        let widths = used.sorted { $0.key < $1.key }.map { "\($0.key) [\($0.value.1)]" }.joined(separator: " ")
        // Descendant and descriptor are direct dictionaries; only binary font/cmap streams need references.
        let descriptor = "<< /Type /FontDescriptor /FontName /LiberationSerif-Regular /Flags 34 /FontBBox [-1000 -1000 2000 2000] /ItalicAngle 0 /Ascent 891 /Descent -216 /CapHeight 655 /StemV 80 /FontFile2 \(base+1) 0 R >>"
        let descendant = "<< /Type /Font /Subtype /CIDFontType2 /BaseFont /LiberationSerif-Regular /CIDSystemInfo << /Registry (Adobe) /Ordering (Identity) /Supplement 0 >> /CIDToGIDMap /Identity /W [\(widths)] /FontDescriptor \(base+4) 0 R >>"
        var chunks = [obj(base, "<< /Type /Font /Subtype /Type0 /BaseFont /LiberationSerif-Regular /Encoding /Identity-H /DescendantFonts [\(base+3) 0 R] /ToUnicode \(base+2) 0 R >>"),
                      obj(base+1, stream(font, extra: "/Length1 \(font.count)")), obj(base+2, stream(Data(cmap.utf8))),
                      obj(base+3, descendant), obj(base+4, descriptor)]
        var kids: [Int] = []; var destination = ""
        for page in selected {
            let widget = next; let ap = next + 1; next += 2
            let isPrimary = page.number == primary.number
            if isPrimary { kids.append(widget) }
            let b = page.box; let w = b[2]-b[0], h = b[3]-b[1]
            func point(_ u: Double, _ v: Double) -> (Double, Double) {
                switch page.rotation {
                case 90: return (b[0]+v*w, b[1]+u*h)
                case 180: return (b[0]+(1-u)*w, b[1]+v*h)
                case 270: return (b[0]+(1-v)*w, b[1]+(1-u)*h)
                default: return (b[0]+u*w, b[1]+(1-v)*h)
                }
            }
            let a = point(placement.x, placement.y), z = point(placement.x+placement.width, placement.y+placement.height)
            let rect = [min(a.0,z.0), min(a.1,z.1), max(a.0,z.0), max(a.1,z.1)].map(num).joined(separator: " ")
            let matrix = [0: "1 0 0 1 0 0", 90: "0 1 -1 0 96 0", 180: "-1 0 0 -1 240 96", 270: "0 -1 1 0 0 240"][page.rotation]!
            var added = [widget]
            if isPrimary {
                destination = "[\(page.number) 0 R /FitR \(rect)]"
                chunks.append(obj(widget, "<< /Type /Annot /Subtype /Widget /Parent \(field) 0 R /P \(page.number) 0 R /Rect [\(rect)] /F 4 /AP << /N \(ap) 0 R >> >>"))
            } else {
                chunks.append(obj(widget, "<< /Type /Annot /Subtype /Stamp /P \(page.number) 0 R /Rect [\(rect)] /F 4 /AP << /N \(ap) 0 R >> >>"))
                added.append(next)
                chunks.append(obj(next, "<< /Type /Annot /Subtype /Link /P \(page.number) 0 R /Rect [\(rect)] /Border [0 0 0] /Dest \(destination) >>"))
                next += 1
            }
            chunks.append(obj(ap, stream(Data(content.utf8), extra: "/Type /XObject /Subtype /Form /BBox [0 0 240 96] /Matrix [\(matrix)] /Resources << /Font << /F \(base) 0 R >> >>")))
            var annots = try value(page.dict, "/Annots") ?? "[]"
            if !annots.hasPrefix("[") { annots = try object(text, ref(annots)) }
            let old = try refs(annots)
            let updated = try set(page.dict, "/Annots", "[" + (old + added).map { "\($0) 0 R" }.joined(separator: " ") + "]")
            chunks.append(obj(page.number, updated))
        }
        return (obj(field, "<< /FT /Sig /T (\(name)) /V \(signature) 0 R /Kids [" + kids.map { "\($0) 0 R" }.joined(separator: " ") + "] >>"), chunks, next)
    }
}
