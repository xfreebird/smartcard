import CoreGraphics
import Foundation
// winlist [owner]: id x y w h layer "title" for on-screen windows of the owner (default eSemnBun)
let owner = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "eSemnBun"
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
for w in list where (w[kCGWindowOwnerName as String] as? String) == owner {
    let b = w[kCGWindowBounds as String] as? [String: CGFloat] ?? [:]
    print(w[kCGWindowNumber as String]!, Int(b["X"] ?? 0), Int(b["Y"] ?? 0), Int(b["Width"] ?? 0), Int(b["Height"] ?? 0),
          w[kCGWindowLayer as String]!, "\"\(w[kCGWindowName as String] as? String ?? "")\"")
}
