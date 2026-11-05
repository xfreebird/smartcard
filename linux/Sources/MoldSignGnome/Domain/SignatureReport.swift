import MoldSignKit

/// Presentation data copied from the verifier. Keeping this value separate permits offline UI scenarios
/// without constructing a core verifier result or pretending the fixture was cryptographically checked.
struct SignatureReport {
    var kind = ""
    var name = ""
    var signer = ""
    var contentIntact = false
    var signatureValid = false
    var chainTrusted = false
    var signingTime = ""
    var timestampTime: String?
    var level = ""
    var summary = ""
    var certificateDetails: [String: String] = [:]

    init() {}
    init(_ report: Validator.Report) {
        certificateDetails = report.certificateDetails
        kind = report.kind
        name = report.name
        signer = report.signer
        contentIntact = report.contentIntact
        signatureValid = report.signatureValid
        chainTrusted = report.chainTrusted
        signingTime = report.signingTime
        timestampTime = report.timestampTime
        level = report.level
        summary = report.summary
    }
}
