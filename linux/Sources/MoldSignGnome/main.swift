import CAdwaita
import Foundation

// eSemnBun for GNOME (LNX-09; codename MoldSign in code and IDs). `--background` starts without a window when
// the browser bridge is on (used by autostart, LNX-12); every other argument goes to GApplication (files, --help…).
// The public name (UX-12): window titles fall back to it, portal dialogs and the About dialog show it.
g_set_application_name("eSemnBun")
var arguments = CommandLine.arguments
let background = arguments.contains("--background")
arguments.removeAll { $0 == "--background" }

let application = MoldSignApp(startHidden: background)
exit(application.run(arguments: arguments))
