// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MoldSign",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "MoldSignKit", targets: ["MoldSignKit"]),
        .executable(name: "esemnbun", targets: ["moldsign"]),   // public name (docs/10 §0.2b); codename target
    ],
    targets: [
        // C shims: PC/SC (macOS PCSC.framework, Linux pcsc-lite) + AES-256/CMAC (CommonCrypto on Apple,
        // OpenSSL libcrypto on Linux) + OpenSSL digests/RSA/TLS helpers for Linux (LNX-01…05)
        .target(
            name: "CPCSC",
            path: "Sources/CPCSC",
            cSettings: [
                // pcsc-lite's <PCSC/winscard.h> includes <pcsclite.h> relative to this directory
                .unsafeFlags(["-I/usr/include/PCSC"], .when(platforms: [.linux])),
            ],
            linkerSettings: [
                .linkedFramework("PCSC", .when(platforms: [.macOS])),
                .linkedLibrary("pcsclite", .when(platforms: [.linux])),
                .linkedLibrary("ssl", .when(platforms: [.linux])),
                .linkedLibrary("crypto", .when(platforms: [.linux])),
            ]
        ),
        // The reverse-engineered core: card driver, secure messaging, PAdES/XAdES, validation, bridge
        .target(
            name: "MoldSignKit",
            dependencies: ["CPCSC"],
            path: "Sources/MoldSignKit",
            swiftSettings: [
                // Linux implementations: OpenSSL crypto/RSA/TLS, POSIX sockets (also usable on macOS for tests,
                // see scripts/test-portable-macos.sh)
                .define("MOLDSIGN_PORTABLE", .when(platforms: [.linux])),
            ],
            linkerSettings: [
                .linkedFramework("CryptoTokenKit", .when(platforms: [.macOS, .iOS])),
            ]
        ),
        // CLI (formerly the MoldSignMac executable); macOS + Linux (spec/cli.md)
        .executableTarget(
            name: "moldsign",
            dependencies: ["MoldSignKit"],
            path: "Sources/moldsign",
            linkerSettings: [
                // ATS exceptions for the HTTP-only MD PKI endpoints (TSA, OCSP, CRL)
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Resources/Info.plist"
                ], .when(platforms: [.macOS]))
            ]
        ),
        .testTarget(
            name: "MoldSignKitTests",
            dependencies: ["MoldSignKit"],
            path: "Tests/MoldSignKitTests",
            resources: [.copy("Fixtures")]
        ),
    ]
)
