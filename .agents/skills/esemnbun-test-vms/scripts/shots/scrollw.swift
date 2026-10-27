import CoreGraphics
import Foundation
// scrollw x y lines   (negative lines = scroll down)
let a = CommandLine.arguments
let p = CGPoint(x: Double(a[1])!, y: Double(a[2])!)
CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: p, mouseButton: .left)?.post(tap: .cghidEventTap)
usleep(100_000)
let lines = Int32(a[3])!
for _ in 0..<abs(lines) {
    CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: lines < 0 ? -3 : 3, wheel2: 0, wheel3: 0)?.post(tap: .cghidEventTap)
    usleep(30_000)
}
