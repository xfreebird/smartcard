import SwiftUI
import MoldSignKit

/// One inserted card. `generation` comes from the reader monitor: a new value means a (re)inserted card.
struct CardSlot: Identifiable, Equatable {
    let reader: String
    let generation: Int
    var certificate: SigningService.CertificateSummary?
    var problemText: PresentationText?
    var problem: String? { problemText?.text }
    var id: String { reader }
}
