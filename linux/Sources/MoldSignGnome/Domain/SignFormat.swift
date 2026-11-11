import Foundation
import MoldSignKit

enum SignFormat: String, CaseIterable, Codable {
    case padesT, xadesBES, xadesT, xadesC

    var label: String {
        switch self {
        case .padesT: return L10n.text(.format_pdf)
        case .xadesBES: return L10n.text(.format_xml)
        case .xadesT: return L10n.text(.format_xml_time)
        case .xadesC: return L10n.text(.format_xml_data)
        }
    }

    var xades: XAdESSigner.Format? {
        switch self {
        case .padesT: return nil
        case .xadesBES: return .bes
        case .xadesT: return .t
        case .xadesC: return .c
        }
    }

    var outputExtension: String { self == .padesT ? "pdf" : "xml" }

    /// PDF → PAdES-T, anything else → XAdES-T detached (docs/10 principle 2).
    static func automatic(for url: URL) -> SignFormat {
        url.pathExtension.lowercased() == "pdf" ? .padesT : .xadesT
    }

    /// Choices offered for a file. A PDF can also get a detached XAdES over its bytes (`<name>-semnat.xml`);
    /// other files pick an XAdES level.
    static func choices(for url: URL) -> [SignFormat] {
        url.pathExtension.lowercased() == "pdf" ? [.padesT, .xadesBES, .xadesT, .xadesC] : [.xadesBES, .xadesT, .xadesC]
    }
}
