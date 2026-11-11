import Foundation
import MoldSignKit

struct DemoDocumentVerifier: DocumentVerifying {
    func verify(_ url: URL) async -> [Validator.Report] { [] }
}
