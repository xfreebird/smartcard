import Foundation
import XCTest
@testable import MoldSignGnome

/// Keeps the test process away from the user's settings, history, keyring and session bus. Runs once, before
/// GLib caches the XDG directories.
enum TestEnvironment {
    static let root: URL = {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("esemnbun-gnome-tests-\(getpid())")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    private static let once: Void = {
        for (name, folder) in [("XDG_CONFIG_HOME", "config"), ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache")] {
            let url = root.appendingPathComponent(folder)
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            setenv(name, url.path, 1)
        }
        // No Secret Service, portal or desktop session from the developer's machine.
        setenv("DBUS_SESSION_BUS_ADDRESS", "unix:path=\(root.path)/no-session-bus", 1)
        unsetenv("FLATPAK_ID")
        // Never start the file manager or a document viewer: record the hand-offs instead.
        DesktopLauncher.revealFile = { path, _ in launched.value.append("reveal:" + path) }
        DesktopLauncher.openFile = { path, _ in launched.value.append("open:" + path) }
    }()

    /// Files the views handed to the desktop ("reveal:<path>", "open:<path>").
    static let launched = Locked<[String]>([])

    static func isolate() { _ = once }

    static func directory(_ name: String = UUID().uuidString) -> URL {
        let url = root.appendingPathComponent("work").appendingPathComponent(name)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// `swift/MoldSignKit/Resources/localhost.p12` in this checkout.
    static var bridgeIdentity: Data? {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("../../../../swift/MoldSignKit/Resources/localhost.p12").standardized
        return try? Data(contentsOf: url)
    }
}

/// Base class: every test runs with the isolated XDG directories and no session bus.
class GnomeTestCase: XCTestCase {
    override class func setUp() {
        super.setUp()
        TestEnvironment.isolate()
    }
}

/// A value shared with worker threads in tests.
final class Locked<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: T
    init(_ value: T) { stored = value }
    var value: T {
        get { lock.lock(); defer { lock.unlock() }; return stored }
        set { lock.lock(); stored = newValue; lock.unlock() }
    }
}
