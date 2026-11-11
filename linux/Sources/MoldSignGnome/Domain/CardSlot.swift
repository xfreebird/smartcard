import Foundation
import MoldSignKit

/// One inserted card. `generation` comes from the reader monitor: a new value means a (re)inserted card.
struct CardSlot: Equatable {
    let reader: String
    let generation: Int
    var certificate: SigningService.CertificateSummary?
    var problem: String?
    var hasStoredPIN = false

    /// Identity of this insertion (the wallet rebuilds its pages when the set of keys changes).
    var key: String { "\(reader)#\(generation)" }
}
