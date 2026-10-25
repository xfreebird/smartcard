// swift-tools-version:5.9
// eSemnBun for GNOME (LNX-09; codename MoldSign): GTK4 + libadwaita through their C API, no wrapper packages.
// Linux: apt install libadwaita-1-dev libsecret-1-dev libpcsclite-dev libssl-dev (see README.md).
// macOS (UI development only): brew install gtk4 libadwaita libsecret pkgconf.
import PackageDescription

let package = Package(
    name: "MoldSignGnome",
    platforms: [.macOS(.v14)],   // MoldSignKit's floor; ignored on Linux
    products: [
        .executable(name: "esemnbun-gnome", targets: ["MoldSignGnome"]),
    ],
    dependencies: [
        .package(path: "../swift/MoldSignKit"),
    ],
    targets: [
        // GTK 4 + libadwaita 1.x headers (pkg-config pulls in gtk4, gio, glib, pango, cairo...)
        .systemLibrary(
            name: "CAdwaita",
            path: "Sources/CAdwaita",
            pkgConfig: "libadwaita-1",
            providers: [
                .apt(["libadwaita-1-dev"]),
                .yum(["libadwaita-devel"]),
                .brew(["libadwaita"]),
            ]
        ),
        // libsecret: the PIN vault on the Secret Service (GNOME Keyring / KWallet), LNX-10
        .systemLibrary(
            name: "CLibSecret",
            path: "Sources/CLibSecret",
            pkgConfig: "libsecret-1",
            providers: [
                .apt(["libsecret-1-dev"]),
                .yum(["libsecret-devel"]),
                .brew(["libsecret"]),
            ]
        ),
        .executableTarget(
            name: "MoldSignGnome",
            dependencies: [
                "CAdwaita",
                "CLibSecret",
                .product(name: "MoldSignKit", package: "MoldSignKit"),
            ],
            path: "Sources/MoldSignGnome",
            swiftSettings: [
                // MSIGN_DEMO_CARDS=<n> (fake cards for screenshots, Model/DemoMode.swift) exists in debug builds only
                .define("MOLDSIGN_DEMO", .when(configuration: .debug)),
            ]
        ),
    ]
)
