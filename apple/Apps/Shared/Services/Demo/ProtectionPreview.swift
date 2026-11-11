import Foundation

/// Presentation-only values; creating a preview never accesses the fictional paths.
struct ProtectionPreview {
    let operation: Int
    let input: URL
    let completed: URL?

    init?(scenario: String) {
        guard scenario.hasPrefix("protect-") else { return nil }
        operation = scenario.contains("remove") ? 2 : scenario.contains("decrypt") ? 1 : 0
        let directory = URL(fileURLWithPath: "/FictionalDocuments", isDirectory: true)
        input = directory.appendingPathComponent(operation == 1 ? "Contract.pdf.symmetric.p7m" : "Contract.pdf")
        completed = scenario.hasSuffix("complete")
            ? directory.appendingPathComponent(operation == 1 ? "decrypted-Contract.pdf" : "Contract.pdf.symmetric.p7m") : nil
    }
}
