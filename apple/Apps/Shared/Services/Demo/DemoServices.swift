import Foundation
import MoldSignKit

@MainActor
struct DemoServices: DemoServiceProviding {
    let files: any DemoDocumentProviding
    var signer: any DocumentSigning {
        #if DEBUG
        if let scenario = ScenarioDocumentSigner.selected { return ScenarioDocumentSigner(scenario: scenario, files: files) }
        #endif
        return DemoDocumentSigner(files: files)
    }
    var verifier: any DocumentVerifying { DemoDocumentVerifier() }

    init() {
        files = DemoDocumentFiles(directory: FileManager.default.temporaryDirectory
            .appendingPathComponent("eSemnBun-demo-\(UUID().uuidString)", isDirectory: true), notice: L10n.text(.demo_output_notice))
    }

    func cards(count: Int, certificates: [SigningService.CertificateSummary]?) -> [CardSlot] {
        let holders = ["Popescu Ion", L10n.text(.ui_mindru_stefan), "Rusu Ana"]
        return (0..<max(0, count)).map { index in
            let reader = index == 0 ? "bit4id miniLector POCKET EVO" : "bit4id miniLector POCKET EVO 0\(index)"
            let holder = holders[index % holders.count]
            let sha = String(format: "%02x", Int(UInt8(truncatingIfNeeded: index * 97 + 20))) + String(repeating: "0", count: 38)
            let certificate = SigningService.CertificateSummary(
                der: Data(), holder: holder, subjectDN: "CN=\(holder),C=MD",
                issuer: "CN=MDQSign,C=MD", issuerName: "MDQSign", serialDecimal: "1298074214877499210738125554536943",
                sha1Hex: sha, notAfter: Calendar.current.date(byAdding: .year, value: 4 - index, to: Date()))
            return CardSlot(reader: reader, generation: 1,
                            certificate: certificates.flatMap { index < $0.count ? $0[index] : nil } ?? certificate)
        }
    }
}
