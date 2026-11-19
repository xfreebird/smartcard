// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CertificateProbeSupport",
    platforms: [.macOS(.v14)],
    dependencies: [.package(name: "MoldSign", path: "../../swift/MoldSignKit")],
    targets: [
        .target(name: "CertificateProbeSupport", dependencies: [.product(name: "MoldSignKit", package: "MoldSign")],
                path: "CertificateProbe", exclude: ["CertificateProbe.swift", "Info.plist"]),
        .testTarget(name: "CertificateProbeSupportTests", dependencies: ["CertificateProbeSupport", .product(name: "MoldSignKit", package: "MoldSign")], path: "Tests")
    ]
)
