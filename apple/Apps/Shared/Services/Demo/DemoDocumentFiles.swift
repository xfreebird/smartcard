import Foundation

/// Outputs are visibly unsigned samples, never copies/modifications of the user's imported bytes.
struct DemoDocumentFiles: DemoDocumentProviding {
    let directory: URL
    let notice: String

    func inputs() throws -> [URL] {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let pdf = directory.appendingPathComponent("Sample-contract.pdf")
        let text = directory.appendingPathComponent("Sample-request.txt")
        try Self.pdf().write(to: pdf, options: .atomic)
        try (notice + "\n\nFictional sample request.\n").write(to: text, atomically: true, encoding: .utf8)
        return [pdf, text]
    }

    func output() throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("DEMO-result-\(UUID().uuidString.prefix(8)).pdf")
        try Self.pdf().write(to: url, options: .withoutOverwriting)
        return url
    }

    /// A one-page, unsigned PDF. ASCII keeps the built-in Helvetica stream deterministic.
    static func pdf() -> Data {
        let stream = "BT /F1 22 Tf 48 740 Td (DEMO SAMPLE) Tj 0 -42 Td /F1 12 Tf (NOT A VALID ELECTRONIC SIGNATURE) Tj 0 -32 Td (Fictional demonstration document. No card or real input was used.) Tj ET\n"
        let objects = [
            "<< /Type /Catalog /Pages 2 0 R >>",
            "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
            "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>",
            "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
            "<< /Length \(stream.utf8.count) >>\nstream\n\(stream)endstream"
        ]
        var pdf = "%PDF-1.4\n"
        var offsets = [0]
        for (index, object) in objects.enumerated() {
            offsets.append(pdf.utf8.count)
            pdf += "\(index + 1) 0 obj\n\(object)\nendobj\n"
        }
        let xref = pdf.utf8.count
        pdf += "xref\n0 6\n0000000000 65535 f \n"
        for offset in offsets.dropFirst() { pdf += String(format: "%010d 00000 n \n", offset) }
        pdf += "trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n\(xref)\n%%EOF\n"
        return Data(pdf.utf8)
    }
}
