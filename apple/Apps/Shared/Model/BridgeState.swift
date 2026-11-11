import SwiftUI
import MoldSignKit

enum BridgeState: Equatable {
    case stopped
    case running
    case portBusy   // the vendor Java server holds 18480/18443 (MAC-08)
    case failed(String)
}
