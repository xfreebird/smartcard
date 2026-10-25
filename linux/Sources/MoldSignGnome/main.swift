import Foundation

// MoldSign for GNOME (LNX-09). `--background` starts without a window when the browser bridge is on
// (used by autostart, LNX-12); every other argument goes to GApplication (files to sign, --help…).
var arguments = CommandLine.arguments
let background = arguments.contains("--background")
arguments.removeAll { $0 == "--background" }

let application = MoldSignApp(startHidden: background)
exit(application.run(arguments: arguments))
