import SwiftUI
import MoldSignKit

/// What the PIN sheet shows. `attemptsLeft` comes from the last 63Cx.
struct PinRequest: Identifiable {
    let id = UUID()
    let holder: String
    let attemptsLeft: Int?
    let canRemember: Bool
    let documentNames: [String]

    init(holder: String, attemptsLeft: Int?, canRemember: Bool, documentNames: [String] = []) {
        self.holder = holder
        self.attemptsLeft = attemptsLeft
        self.canRemember = canRemember
        self.documentNames = documentNames
    }
}
