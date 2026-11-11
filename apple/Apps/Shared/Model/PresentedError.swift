import SwiftUI
import MoldSignKit

struct PresentedError: Equatable {
    let messageText: PresentationText
    let recoveryText: PresentationText
    var message: String { messageText.text }
    var recovery: String { recoveryText.text }
}
