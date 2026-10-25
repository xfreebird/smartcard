import Foundation

/// Which callers may use the local bridge (SEC-01). Mirrors the vendor `AllowedSites`:
/// each pattern becomes a regex (`.` → `\.`, `?` → `.?`, `*` → `.*`) that must match the WHOLE
/// `Origin` header. Requests without an `Origin` (non-browser clients) need the header
/// `moldSign: DesktopSuiteClient`.
public struct BridgeOriginPolicy {
    public let patterns: [String]
    private let regexes: [NSRegularExpression]

    public init(patterns: [String]) {
        self.patterns = patterns
        regexes = patterns.compactMap { p in
            let rx = p.replacingOccurrences(of: ".", with: "\\.")
                .replacingOccurrences(of: "?", with: ".?")
                .replacingOccurrences(of: "*", with: ".*")
            return try? NSRegularExpression(pattern: "^(?:" + rx + ")$")
        }
    }

    /// Parses `key=value` lines (vendor `allowedURL.properties` format). All values count, even duplicate keys.
    public init(propertiesText: String) {
        self.init(patterns: propertiesText.split(whereSeparator: \.isNewline).compactMap { line in
            let t = line.trimmingCharacters(in: .whitespaces)
            guard !t.isEmpty, !t.hasPrefix("#"), let eq = t.firstIndex(of: "=") else { return nil }
            return String(t[t.index(after: eq)...]).trimmingCharacters(in: .whitespaces)
        })
    }

    public func allows(origin: String?, moldSignHeader: String?) -> Bool {
        guard let origin, !origin.isEmpty else { return moldSignHeader == "DesktopSuiteClient" }
        let range = NSRange(origin.startIndex..., in: origin)
        return regexes.contains { $0.firstMatch(in: origin, range: range) != nil }
    }

    /// Vendor list, kept identical to `spec/bridge/allowed-origins.properties` (a test enforces it).
    public static let vendorDefault = BridgeOriginPolicy(patterns: vendorPatterns)

    static let vendorPatterns = [
        "*.cts.md",
        "*.infosec.md",
        "*.itsec.md",
        "http://localhost",
        "*.pki.md",
        "https://msign.gov.md",
        "https://testmsign.gov.md",
        "http://siaas.gov.md",
        "https://mpass.gov.md",
        "https://testmpass.gov.md",
        "http://moldlislocal",
        "*.cadastru.md",
        "https://smaedc.cadastru.md",
        "http://bic.infodebit.md",
        "https://bic.infodebit.md",
        "http://test.infodebit.md/",
        "https://online.energbank.com",
        "http://ent2.bicr.md",
        "http://tst.bicr.md",
        "http://bkp.bicr.md",
        "http://sigun.bicr.md",
        "http://dev.bicr.md",
        "*.bicr.md",
        "http://moldlis.asp.gov.md",
        "https://moldlis.asp.gov.md",
        "http://moldlis-test.asp.gov.md",
        "https://moldlis-test.asp.gov.md",
        "https://delivery-moldlis.sinergise.com",
        "http://docker1.moldlis.mda.sinergise.com",
        "http://dms",
        "http://dms.moldovagaz.md",
        "http://dev-dms.moldovagaz.md",
        "http://dev-dms",
        "https://dms",
        "https://dms.moldovagaz.md",
        "https://dev-dms.moldovagaz.md",
        "https://dev-dms",
        "http://teaming.lan.bnm.md",
        "http://sged.lan.bnm.md",
        "https://sged.lan.bnm.md",
        "http://sgedtest.lan.bnm.md",
        "https://sgedtest.lan.bnm.md",
        "https://crmapp.lan.bnm.md",
        "https://crmdev1.lan.bnm.md",
        "https://mpass.staging.egov.md",
        "https://msign.staging.egov.md",
        "https://docsign.esempla.ml",
        "https://isign.w.mcb.md",
        "https://sgre.w.mcb.md",
        "https://sgre-test.w.mcb.md",
        "https://sgre.micb.md",
        "https://*.micb.md",
        "https://*.mcb.md",
        "https://sgret.micb.md",
        "https://sgre-dev.mcb.md",
        "https://sgre.mcb.md",
        "https://elo-test.w.mcb.md",
        "https://elo.w.mcb.md",
        "https://test-yoda.maib.md",
        "https://yoda.maib.md",
        "https://bussiness.maib.md",
        "https://*.maib.md",
        "*.comertbank.md",
        "*.fgdsb.md",
        "https://my.e-cont.md",
        "https://efactura.e-cont.md",
        "*.edocs.gov.md",
        "https://edocs.gov.md",
        "*.gov.md",
        "https://patrimoniu-gov.md",
        "https://dms.md",
        "*.lan.bnm.md",
        "*.bnm.md"
    ]
}
