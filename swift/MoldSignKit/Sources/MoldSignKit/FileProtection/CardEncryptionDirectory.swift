import Foundation

/// A narrow PKCS#15 reader: unknown key/PIN encodings are unavailable, never guessed.
struct CardEncryptionDirectory {
    struct Key: Equatable, Sendable {
        let id: Data
        let label: String
        let reference: UInt8
        let modulusBytes: Int
        let pinReference: UInt8
        let minimumPINLength: Int
        let maximumPINLength: Int
        let certificatePath: Data
    }
    static func keys(privateKeys: Data, certificates: Data, authentication: Data) throws -> [Key] {
        let pins = try ProtectionASN1.records(authentication)
        let certs = try ProtectionASN1.records(certificates)
        var result: [Key] = []
        for record in try ProtectionASN1.records(privateKeys) {
            guard record.tag == 0x30 else { continue } // RSA only
            let fields = record.children
            guard fields.count >= 3, fields[0].tag == 0x30, fields[1].tag == 0x30 else { continue }
            let common = fields[0].children, attributes = fields[1].children
            // userConsent marks signature keys in the vendor middleware.
            guard !common.contains(where: { $0.tag == 2 && $0.content.contains(where: { $0 != 0 }) }),
                  let authID = common.first(where: { $0.tag == 4 })?.content,
                  attributes.count >= 3, attributes[0].tag == 4, attributes[1].tag == 3,
                  attributes[1].content.count >= 2, attributes[1].content[1] & 0x40 != 0,
                  let referenceNode = attributes.dropFirst(2).first(where: { $0.tag == 2 }),
                  let reference = try? referenceNode.positiveInteger(), (1...255).contains(reference),
                  let type = fields.first(where: { $0.tag == 0xa1 })?.children.first,
                  type.tag == 0x30, type.children.count >= 2,
                  type.children[0].tag == 0x30, type.children[0].children.first?.tag == 4,
                  type.children[1].tag == 2,
                  let bits = try? type.children[1].positiveInteger(), [2048,3072,4096,8192].contains(bits)
            else { continue }
            let id = attributes[0].content
            let matchingCerts = certs.filter {
                $0.tag == 0x30 && $0.children.count >= 3 && $0.children[1].tag == 0x30 &&
                $0.children[1].children.first?.tag == 4 && $0.children[1].children.first?.content == id
            }
            guard matchingCerts.count == 1,
                  let certType = matchingCerts[0].children.first(where: { $0.tag == 0xa1 })?.children.first,
                  certType.tag == 0x30,
                  let path = certType.children.first, path.tag == 0x30,
                  path.children.count == 1, path.children[0].tag == 4,
                  path.children[0].content.count == 2 // Generic ADF relative EF only
            else { continue }
            let matchingPINs = pins.filter {
                $0.tag == 0x30 && $0.children.count >= 3 && $0.children[1].tag == 0x30 &&
                $0.children[1].children.first?.tag == 4 && $0.children[1].children.first?.content == authID
            }
            guard matchingPINs.count == 1,
                  let pinType = matchingPINs[0].children.first(where: { $0.tag == 0xa1 })?.children.first,
                  pinType.tag == 0x30, pinType.children.count >= 4 else { continue }
            let pin = pinType.children
            guard pin[0].tag == 3, pin[0].content.count >= 2, pin[0].content[1] & 0x07 == 0, pin[1].tag == 10,
                  // Numeric PINs have identical bytes in ASCII-numeric and UTF-8.
                  // Callers still restrict input to digits; other encodings stay unavailable.
                  [1,2].contains((try? pin[1].positiveInteger()) ?? -1),
                  pin[2].tag == 2, let minimum = try? pin[2].positiveInteger(),
                  pin[3].tag == 2, let stored = try? pin[3].positiveInteger(),
                  let ref = pin.first(where: { $0.tag == 0x80 }),
                  let pinReference = try? ref.positiveInteger(), pinReference == 3
            else { continue }
            let maximum = pin.dropFirst(4).first(where: { $0.tag == 2 }).flatMap { try? $0.positiveInteger() } ?? stored
            guard minimum >= 4, maximum >= minimum, maximum <= 8 else { continue }
            result.append(Key(id: id, label: common.first(where: { $0.tag == 12 }).flatMap { String(data: $0.content, encoding: .utf8) } ?? "",
                              reference: UInt8(reference), modulusBytes: bits/8, pinReference: UInt8(pinReference),
                              minimumPINLength: minimum, maximumPINLength: maximum, certificatePath: path.children[0].content))
        }
        // Duplicate key identities/references are ambiguous; never ask for a PIN for them.
        return result.filter { key in result.filter { $0.id == key.id || $0.reference == key.reference }.count == 1 }
    }
}
