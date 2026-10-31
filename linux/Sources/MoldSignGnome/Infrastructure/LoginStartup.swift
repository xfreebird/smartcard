import Foundation

/// User-level login registration; no daemon, elevated privilege, or PIN is involved.
enum LoginStartup {
    static var sandboxed: Bool { ProcessInfo.processInfo.environment["FLATPAK_ID"] != nil }

    static func configure(_ enabled: Bool, portal: BackgroundPortal, completion: @escaping (Bool) -> Void) {
        if sandboxed {
            portal.requestBackground(reason: L10n.text(.ui_monitor_card_insertion_after_login),
                                     autostart: enabled, completion: completion)
            return
        }
        do {
            let directory = URL(fileURLWithPath: userConfigDir).appendingPathComponent("autostart")
            let entry = directory.appendingPathComponent("md.moldsign.MoldSign.desktop")
            if enabled {
                #if os(Linux)
                let executable = URL(fileURLWithPath: "/proc/self/exe").resolvingSymlinksInPath().path
                #else
                let executable = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath().path
                #endif
                guard !executable.contains("\n"), !executable.contains("\r") else { completion(false); return }
                // Desktop Entry Exec quoted-argument escaping (not shell escaping).
                let quoted = executable.reduce(into: "") { value, character in
                    if "\\\"`$".contains(character) { value.append("\\") }
                    value.append(character)
                }
                let text = """
                [Desktop Entry]
                Type=Application
                Name=eSemnBun
                Exec="\(quoted)" --background
                Icon=md.moldsign.MoldSign
                Terminal=false
                X-GNOME-Autostart-enabled=true
                NoDisplay=true

                """
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                         attributes: [.posixPermissions: 0o700])
                try text.write(to: entry, atomically: true, encoding: .utf8)
            } else if FileManager.default.fileExists(atPath: entry.path) {
                try FileManager.default.removeItem(at: entry)
            }
            completion(true)
        } catch {
            completion(false)
        }
    }
}
