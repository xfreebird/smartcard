import Foundation

/// X.509 fields shared by OCSP and CMS, with every field bounded by its parent sequence.
struct CertFields {
    let serialTLV: Data
    let issuerDER: Data
    let subjectDER: Data
    let publicKeyBits: Data

    init(_ certificate: Data) throws {
        let data = Data(certificate)
        let outer = try DER.element(data, at: 0)
        guard outer.tag == 0x30 else { throw CardError.signFailed("Invalid certificate") }
        let tbs = try DER.element(data, at: outer.content.lowerBound)
        guard tbs.tag == 0x30, tbs.range.upperBound <= outer.content.upperBound else {
            throw CardError.signFailed("Invalid certificate body")
        }
        var position = tbs.content.lowerBound
        func next() throws -> DER.Element {
            let element = try DER.element(data, at: position)
            guard element.range.upperBound <= tbs.content.upperBound else { throw CardError.signFailed("Truncated certificate field") }
            position = element.range.upperBound
            return element
        }
        var serial = try next()
        if serial.tag == 0xA0 { serial = try next() }
        guard serial.tag == 0x02 else { throw CardError.signFailed("Invalid certificate serial") }
        serialTLV = data.subdata(in: serial.range)
        _ = try next() // signature algorithm
        let issuer = try next()
        guard issuer.tag == 0x30 else { throw CardError.signFailed("Invalid certificate issuer") }
        issuerDER = data.subdata(in: issuer.range)
        _ = try next() // validity
        let subject = try next()
        guard subject.tag == 0x30 else { throw CardError.signFailed("Invalid certificate subject") }
        subjectDER = data.subdata(in: subject.range)
        let spki = try next()
        guard spki.tag == 0x30 else { throw CardError.signFailed("Invalid certificate key") }
        let algorithm = try DER.element(data, at: spki.content.lowerBound)
        guard algorithm.range.upperBound < spki.content.upperBound else { throw CardError.signFailed("Missing public key") }
        let bits = try DER.element(data, at: algorithm.range.upperBound)
        guard bits.tag == 0x03, bits.content.count > 1, bits.range.upperBound <= spki.content.upperBound else {
            throw CardError.signFailed("SPKI bit string")
        }
        publicKeyBits = data.subdata(in: (bits.content.lowerBound + 1)..<bits.content.upperBound)
    }
}
