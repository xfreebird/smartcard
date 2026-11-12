import Foundation

extension IdentityCardContent {
    init(card: CardSlot) {
        let certificate = card.certificate
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd MM yyyy"
        let accessible: String
        if let problem = card.problem {
            accessible = "\(certificate?.holder ?? card.reader), \(problem)"
        } else if let certificate {
            let until = certificate.notAfter.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "—"
            accessible = L10n.text(.ui_value_identity_card_valid_until_value, certificate.holder, until)
        } else {
            accessible = L10n.text(.ui_card_in_value_reading, card.reader)
        }
        let byte = certificate.flatMap { UInt8($0.sha1Hex.prefix(2), radix: 16) } ?? 128
        self.init(reader: card.reader, surname: certificate?.surname, givenNames: certificate?.givenNames,
                  validUntil: certificate.map { $0.notAfter.map(formatter.string(from:)) ?? "—" },
                  issuer: certificate?.issuerName, hasIdentity: certificate != nil, problem: card.problem,
                  hueShift: Double(byte) / 255 * 40 - 20, accessibilityLabel: accessible,
                  labels: IdentityCardLabels(surname: L10n.text(.ui_surname), givenNames: L10n.text(.ui_given_names),
                    validUntil: L10n.text(.ui_valid_until_2), issuer: L10n.text(.ui_issuer),
                    selected: L10n.text(.ui_used_for_signing), reading: L10n.text(.ui_reading_the_card),
                    signing: L10n.text(.ui_signing), ready: L10n.text(.ui_ready_to_sign)))
    }
}
