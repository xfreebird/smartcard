import CAdwaita
import Foundation

/// `org.freedesktop.portal.Background` over GDBus (UX-01, UX-07, LNX-12). GNOME has no tray icon: the status
/// light's text goes to `SetStatus`, which GNOME Shell shows under Quick Settings → Background Apps, and
/// `RequestBackground` asks to keep running after the window closes (the browser bridge).
///
/// Best effort everywhere: no session bus (macOS dev builds), no portal, or a portal older than version 2
/// (no `SetStatus`) is logged once and the app carries on; the window's wallet and action bar still show the
/// same status. Host (non-Flatpak) apps are identified by the portal from their systemd scope, which GNOME
/// Shell names after the .desktop file (`app-gnome-md.moldsign.MoldSign-….scope`).
final class BackgroundPortal {
    private let connection: OpaquePointer?
    private var lastStatus: String?
    private var statusUnsupported = false
    private var requested = false

    private static let bus = "org.freedesktop.portal.Desktop"
    private static let path = "/org/freedesktop/portal/desktop"
    private static let interface = "org.freedesktop.portal.Background"
    /// The portal rejects longer messages.
    static let maxStatusLength = 96

    init(application: UnsafeMutablePointer<AdwApplication>) {
        connection = g_application_get_dbus_connection(application.cast())
        if connection == nil {
            logInfo("background portal: no D-Bus session bus, status stays in the window")
        }
    }

    /// `SetStatus({message})`; repeated identical messages are not sent again.
    func setStatus(_ text: String) {
        guard let connection, !statusUnsupported else { return }
        let message = text.count > Self.maxStatusLength ? String(text.prefix(Self.maxStatusLength - 1)) + "…" : text
        guard message != lastStatus else { return }
        lastStatus = message
        let options = Self.vardict([("message", g_variant_new_string(message))])
        call(connection, "SetStatus", Self.tuple([options])) { [weak self] error in
            guard let error else { return }
            // older portals (no SetStatus, version < 2) or no portal at all: say so once, then stop trying
            self?.statusUnsupported = true
            logInfo("background portal: SetStatus unavailable (\(error)); status stays in the window")
        }
    }

    /// The portal owns Flatpak login registration. Wait for the Request response rather than
    /// treating the initial object-path reply as permission to enable autostart.
    func requestBackground(reason: String, autostart: Bool = false,
                           completion: ((Bool) -> Void)? = nil) {
        guard let connection else { completion?(false); return }
        if requested && completion == nil { return }
        requested = true
        let token = "moldsign\(UInt32.random(in: 1...UInt32.max))"
        let sender = String(cString: g_dbus_connection_get_unique_name(connection))
            .dropFirst().replacingOccurrences(of: ".", with: "_")
        let requestPath = "/org/freedesktop/portal/desktop/request/\(sender)/\(token)"
        var subscription: guint = 0
        var completed = false
        let finish: (Bool) -> Void = { accepted in
            guard !completed else { return }
            completed = true
            if subscription != 0 { g_dbus_connection_signal_unsubscribe(connection, subscription) }
            completion?(accepted)
        }
        let handler: (OpaquePointer?) -> Void = { parameters in
            guard let parameters else { finish(false); return }
            guard let code = g_variant_get_child_value(parameters, 0),
                  let results = g_variant_get_child_value(parameters, 1) else { finish(false); return }
            defer { g_variant_unref(code); g_variant_unref(results) }
            guard g_variant_get_uint32(code) == 0 else { finish(false); return }
            if autostart || completion != nil {
                guard let allowed = g_variant_lookup_value(results, "autostart", nil) else { finish(false); return }
                defer { g_variant_unref(allowed) }
                finish((g_variant_get_boolean(allowed) != 0) == autostart)
            } else {
                finish(true)
            }
        }
        let data = Unmanaged.passRetained(Box(handler)).toOpaque()
        let callback: GDBusSignalCallback = { _, _, _, _, _, parameters, data in
            guard let data else { return }
            Unmanaged<Box<(OpaquePointer?) -> Void>>.fromOpaque(data).takeUnretainedValue().value(parameters)
        }
        let destroy: GDestroyNotify = { data in
            if let data { Unmanaged<Box<(OpaquePointer?) -> Void>>.fromOpaque(data).release() }
        }
        subscription = g_dbus_connection_signal_subscribe(connection, Self.bus,
            "org.freedesktop.portal.Request", "Response", requestPath, nil,
            GDBusSignalFlags(rawValue: 0), callback, data, destroy)
        var entries: [(String, OpaquePointer?)] = [
            ("reason", g_variant_new_string(reason)),
            ("autostart", g_variant_new_boolean(autostart ? 1 : 0)),
            ("handle_token", g_variant_new_string(token)),
        ]
        if autostart {
            withCStringArray(["esemnbun-gnome", "--background"]) { strings in
                entries.append(("commandline", g_variant_new_strv(strings, -1)))
            }
        }
        call(connection, "RequestBackground", Self.tuple([g_variant_new_string(""), Self.vardict(entries)])) { error in
            if let error {
                logInfo("background portal: RequestBackground failed (\(error))")
                finish(false)
            }
        }
        // Avoid holding Preferences disabled indefinitely if the portal disappears or never responds.
        after(milliseconds: 60_000) {
            guard !completed else { return }
            g_dbus_connection_call(connection, Self.bus, requestPath,
                "org.freedesktop.portal.Request", "Close", nil, nil,
                GDBusCallFlags(rawValue: 0), 5000, nil, nil, nil)
            finish(false)
        }
    }

    // MARK: - GDBus / GVariant plumbing (g_variant_new is variadic: build with the typed constructors)

    private func call(_ connection: OpaquePointer, _ method: String, _ parameters: OpaquePointer?,
                      completion: @escaping (String?) -> Void) {
        let (callback, data) = asyncReady { result in
            var error: UnsafeMutablePointer<GError>?
            let reply = g_dbus_connection_call_finish(connection, result, &error)
            if let reply { g_variant_unref(reply) }
            completion(takeError(error))
        }
        // `parameters` is floating: the call consumes it. Flags 0 = G_DBUS_CALL_FLAGS_NONE (raw value: flag enums
        // are renamed in Swift on recent GLib, see App.swift).
        g_dbus_connection_call(connection, Self.bus, Self.path, Self.interface, method, parameters, nil,
                               GDBusCallFlags(rawValue: 0), 5000, nil, callback, data)
    }

    /// `a{sv}` from (key, value) pairs; values are wrapped in variants here.
    private static func vardict(_ entries: [(String, OpaquePointer?)]) -> OpaquePointer? {
        let type = g_variant_type_new("a{sv}")
        let builder = g_variant_builder_new(type)
        g_variant_type_free(type)
        for (key, value) in entries {
            g_variant_builder_add_value(builder, g_variant_new_dict_entry(g_variant_new_string(key), g_variant_new_variant(value)))
        }
        let dict = g_variant_builder_end(builder)
        g_variant_builder_unref(builder)
        return dict
    }

    private static func tuple(_ children: [OpaquePointer?]) -> OpaquePointer? {
        children.withUnsafeBufferPointer { g_variant_new_tuple($0.baseAddress, gsize(children.count)) }
    }
}
