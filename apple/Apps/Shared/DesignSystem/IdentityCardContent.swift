/// Display data only: certificates and reader models are mapped outside the design system.
struct IdentityCardContent: Equatable {
    let reader: String
    let surname: String?
    let givenNames: String?
    let validUntil: String?
    let issuer: String?
    let hasIdentity: Bool
    let problem: String?
    let hueShift: Double
    let accessibilityLabel: String
    let labels: IdentityCardLabels
}
