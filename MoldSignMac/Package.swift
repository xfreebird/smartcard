// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MoldSignMac",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "CPCSC",
            path: "CPCSC",
            linkerSettings: [
                .linkedFramework("PCSC"),
                .linkedFramework("Security")
            ]
        ),
        .executableTarget(
            name: "MoldSignMac",
            dependencies: ["CPCSC"],
            path: "MoldSignMac",
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Resources/Info.plist"
                ])
            ]
        ),
        .testTarget(
            name: "MoldSignMacTests",
            dependencies: ["MoldSignMac"],
            path: "MoldSignMacTests"
        ),
    ]
)
