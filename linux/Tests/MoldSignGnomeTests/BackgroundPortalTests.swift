import CAdwaita
import Foundation
import XCTest
@testable import MoldSignGnome

/// org.freedesktop.portal.Background against a private dbus-daemon and an in-process fake portal.
final class BackgroundPortalTests: GnomeTestCase {
    private var daemon: Process?
    private var client: OpaquePointer?
    private var server: OpaquePointer?
    private var portal: FakePortal!
    private var registration: guint = 0

    override func setUpWithError() throws {
        let executable = ["/usr/bin/dbus-daemon", "/bin/dbus-daemon"].first { FileManager.default.isExecutableFile(atPath: $0) }
        guard let executable else {
            if ProcessInfo.processInfo.environment["MSIGN_REQUIRE_DISPLAY"] == "1" {
                XCTFail("dbus-daemon is required for the Background portal tests")
            }
            throw XCTSkip("dbus-daemon is not installed")
        }
        let folder = TestEnvironment.directory()
        let config = folder.appendingPathComponent("bus.conf")
        try """
        <busconfig>
          <type>session</type>
          <listen>unix:dir=\(folder.path)</listen>
          <auth>EXTERNAL</auth>
          <policy context="default"><allow send_destination="*" eavesdrop="true"/><allow eavesdrop="true"/><allow own="*"/></policy>
        </busconfig>
        """.write(to: config, atomically: true, encoding: .utf8)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = ["--config-file=\(config.path)", "--nofork", "--print-address=1"]
        let output = Pipe()
        process.standardOutput = output
        try process.run()
        daemon = process
        let line = output.fileHandleForReading.availableData
        let address = String(decoding: line, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertFalse(address.isEmpty)
        client = try connect(address)
        server = try connect(address)
        portal = FakePortal()
        try portal.serve(on: server!)
    }

    override func tearDown() {
        if let server {
            if portal.registration != 0 { g_dbus_connection_unregister_object(server, portal.registration) }
            g_dbus_connection_close_sync(server, nil, nil)
            g_object_unref(server.raw)
        }
        if let client { g_dbus_connection_close_sync(client, nil, nil); g_object_unref(client.raw) }
        daemon?.terminate()
        daemon?.waitUntilExit()
        GTKTest.pump()
        unsetenv("FLATPAK_ID")
    }

    private func connect(_ address: String) throws -> OpaquePointer {
        var error: UnsafeMutablePointer<GError>?
        // AUTHENTICATION_CLIENT | MESSAGE_BUS_CONNECTION (flag enums imported as raw values, see App.swift)
        let connection = g_dbus_connection_new_for_address_sync(address, GDBusConnectionFlags(rawValue: 1 | 8), nil, nil, &error)
        if let message = takeError(error) { throw NSError(domain: "dbus", code: 1, userInfo: [NSLocalizedDescriptionKey: message]) }
        return connection!
    }

    func testStatusIsSentOnceTruncatedAndStopsWhenUnsupported() {
        let background = BackgroundPortal(connection: client)
        background.setStatus("Card connected · POPESCU ION")
        background.setStatus("Card connected · POPESCU ION")
        XCTAssertTrue(GTKTest.pump(until: { self.portal.statuses.count == 1 }))
        GTKTest.pump(0.1)
        XCTAssertEqual(portal.statuses, ["Card connected · POPESCU ION"], "Identical messages are not repeated")
        background.setStatus(String(repeating: "x", count: 150))
        XCTAssertTrue(GTKTest.pump(until: { self.portal.statuses.count == 2 }))
        XCTAssertEqual(portal.statuses[1].count, BackgroundPortal.maxStatusLength)
        XCTAssertTrue(portal.statuses[1].hasSuffix("…"))
        portal.failSetStatus = true
        background.setStatus("No card connected")
        XCTAssertTrue(GTKTest.pump(until: { self.portal.setStatusCalls == 3 }))
        GTKTest.pump(0.1)
        background.setStatus("Card connected · CIOBANU MARIA")
        GTKTest.pump(0.2)
        XCTAssertEqual(portal.setStatusCalls, 3, "An old portal without SetStatus is not asked again")
    }

    func testBackgroundRequestWaitsForTheResponseAndChecksAutostart() {
        let background = BackgroundPortal(connection: client)
        var answers: [Bool] = []
        background.requestBackground(reason: "Monitor cards", autostart: true) { answers.append($0) }
        XCTAssertTrue(GTKTest.pump(until: { answers.count == 1 }))
        XCTAssertEqual(answers, [true])
        XCTAssertEqual(portal.requests.last?.reason, "Monitor cards")
        XCTAssertEqual(portal.requests.last?.autostart, true)
        XCTAssertEqual(portal.requests.last?.commandline, ["esemnbun-gnome", "--background"])
        portal.grantAutostart = false
        background.requestBackground(reason: "Monitor cards", autostart: true) { answers.append($0) }
        XCTAssertTrue(GTKTest.pump(until: { answers.count == 2 }))
        XCTAssertEqual(answers[1], false, "The portal kept login startup off")
        portal.responseCode = 1
        background.requestBackground(reason: "Monitor cards", autostart: false) { answers.append($0) }
        XCTAssertTrue(GTKTest.pump(until: { answers.count == 3 }))
        XCTAssertEqual(answers[2], false, "A cancelled request is a refusal")
        portal.responseCode = 0
        portal.grantAutostart = nil
        background.requestBackground(reason: "Monitor cards", autostart: false) { answers.append($0) }
        XCTAssertTrue(GTKTest.pump(until: { answers.count == 4 }))
        XCTAssertEqual(answers[3], false, "A response without the autostart result is not trusted")
    }

    func testFireAndForgetRequestIsSentOnceAndUnansweredRequestsTimeOut() {
        let background = BackgroundPortal(connection: client)
        background.requestBackground(reason: "Keep the browser connection")
        background.requestBackground(reason: "Keep the browser connection")
        XCTAssertTrue(GTKTest.pump(until: { self.portal.requests.count == 1 }))
        GTKTest.pump(0.2)
        XCTAssertEqual(portal.requests.count, 1)
        portal.respond = false
        background.responseTimeout = 150
        var answer: Bool?
        background.requestBackground(reason: "Monitor cards", autostart: true) { answer = $0 }
        XCTAssertTrue(GTKTest.pump(until: { answer != nil }, timeout: 3))
        XCTAssertEqual(answer, false)
        portal.failRequest = true
        answer = nil
        background.requestBackground(reason: "Monitor cards", autostart: true) { answer = $0 }
        XCTAssertTrue(GTKTest.pump(until: { answer != nil }, timeout: 3))
        XCTAssertEqual(answer, false)
    }

    func testSandboxedLoginStartupGoesThroughThePortal() {
        setenv("FLATPAK_ID", "md.moldsign.MoldSign", 1)
        let background = BackgroundPortal(connection: client)
        var answer: Bool?
        LoginStartup.configure(true, portal: background) { answer = $0 }
        XCTAssertTrue(GTKTest.pump(until: { answer != nil }))
        XCTAssertEqual(answer, true)
        XCTAssertEqual(portal.requests.last?.reason, L10n.text(.ui_monitor_card_insertion_after_login))
    }
}

/// Just enough of xdg-desktop-portal's Background interface, recording what the app sends.
private final class FakePortal {
    struct Request { let reason: String; let autostart: Bool; let commandline: [String] }
    var statuses: [String] = []
    var setStatusCalls = 0
    var failSetStatus = false
    var failRequest = false
    var respond = true
    var responseCode: UInt32 = 0
    var grantAutostart: Bool? = true
    var requests: [Request] = []
    var registration: guint = 0
    private var connection: OpaquePointer?
    private var vtable = UnsafeMutablePointer<GDBusInterfaceVTable>.allocate(capacity: 1)

    deinit { vtable.deallocate() }

    func serve(on connection: OpaquePointer) throws {
        self.connection = connection
        var error: UnsafeMutablePointer<GError>?
        let xml = """
        <node><interface name="org.freedesktop.portal.Background">
          <method name="SetStatus"><arg type="a{sv}" name="options" direction="in"/></method>
          <method name="RequestBackground"><arg type="s" name="parent_window" direction="in"/>
            <arg type="a{sv}" name="options" direction="in"/><arg type="o" name="handle" direction="out"/></method>
        </interface></node>
        """
        guard let node = g_dbus_node_info_new_for_xml(xml, &error) else { throw XCTSkip(takeError(error) ?? "bad XML") }
        defer { g_dbus_node_info_unref(node) }
        vtable.initialize(to: GDBusInterfaceVTable())
        vtable.pointee.method_call = { _, sender, _, _, method, parameters, invocation, data in
            guard let data, let method else { return }
            Unmanaged<FakePortal>.fromOpaque(data).takeUnretainedValue()
                .call(String(cString: method), sender: sender.map { String(cString: $0) } ?? "", parameters, invocation)
        }
        registration = g_dbus_connection_register_object(connection, "/org/freedesktop/portal/desktop",
            g_dbus_node_info_lookup_interface(node, "org.freedesktop.portal.Background"), vtable,
            Unmanaged.passUnretained(self).toOpaque(), nil, &error)
        if let message = takeError(error) { throw XCTSkip(message) }
        let name = [g_variant_new_string("org.freedesktop.portal.Desktop"), g_variant_new_uint32(4)]
        let reply = name.withUnsafeBufferPointer {
            g_dbus_connection_call_sync(connection, "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
                                        "RequestName", g_variant_new_tuple($0.baseAddress, 2), nil, GDBusCallFlags(rawValue: 0), -1, nil, &error)
        }
        if let reply { g_variant_unref(reply) }
        if let message = takeError(error) { throw XCTSkip(message) }
    }

    private func call(_ method: String, sender: String, _ parameters: OpaquePointer?, _ invocation: OpaquePointer?) {
        let options = g_variant_get_child_value(parameters, method == "SetStatus" ? 0 : 1)
        defer { g_variant_unref(options) }
        func lookup(_ key: String) -> OpaquePointer? { g_variant_lookup_value(options, key, nil) }
        if method == "SetStatus" {
            setStatusCalls += 1
            if failSetStatus {
                return g_dbus_method_invocation_return_dbus_error(invocation, "org.freedesktop.DBus.Error.UnknownMethod", "No SetStatus in version 1")
            }
            if let message = lookup("message") { statuses.append(String(cString: g_variant_get_string(message, nil))); g_variant_unref(message) }
            return g_dbus_method_invocation_return_value(invocation, nil)
        }
        if failRequest { return g_dbus_method_invocation_return_dbus_error(invocation, "org.freedesktop.portal.Error.Failed", "Denied") }
        var reason = "", token = "", autostart = false, commandline: [String] = []
        if let value = lookup("reason") { reason = String(cString: g_variant_get_string(value, nil)); g_variant_unref(value) }
        if let value = lookup("handle_token") { token = String(cString: g_variant_get_string(value, nil)); g_variant_unref(value) }
        if let value = lookup("autostart") { autostart = g_variant_get_boolean(value) != 0; g_variant_unref(value) }
        if let value = lookup("commandline") {
            for index in 0..<g_variant_n_children(value) {
                let item = g_variant_get_child_value(value, index)
                commandline.append(String(cString: g_variant_get_string(item, nil)))
                g_variant_unref(item)
            }
            g_variant_unref(value)
        }
        requests.append(Request(reason: reason, autostart: autostart, commandline: commandline))
        let path = "/org/freedesktop/portal/desktop/request/\(sender.dropFirst().replacingOccurrences(of: ".", with: "_"))/\(token)"
        let handle = [g_variant_new_object_path(path)]
        handle.withUnsafeBufferPointer { g_dbus_method_invocation_return_value(invocation, g_variant_new_tuple($0.baseAddress, 1)) }
        guard respond, let connection else { return }
        let code = responseCode, granted = grantAutostart
        after(milliseconds: 20) {
            let type = g_variant_type_new("a{sv}")
            let builder = g_variant_builder_new(type)
            g_variant_type_free(type)
            if let granted {
                g_variant_builder_add_value(builder, g_variant_new_dict_entry(g_variant_new_string("autostart"),
                                                                              g_variant_new_variant(g_variant_new_boolean(granted ? 1 : 0))))
            }
            let results = g_variant_builder_end(builder)
            g_variant_builder_unref(builder)
            let response = [g_variant_new_uint32(code), results]
            var error: UnsafeMutablePointer<GError>?
            response.withUnsafeBufferPointer {
                _ = g_dbus_connection_emit_signal(connection, nil, path, "org.freedesktop.portal.Request", "Response",
                                                  g_variant_new_tuple($0.baseAddress, 2), &error)
            }
            _ = takeError(error)
        }
    }
}
