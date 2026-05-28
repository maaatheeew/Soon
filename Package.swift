// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Soon",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        .executable(
            name: "Soon",
            targets: ["CalendarMenu"]
        )
    ],
    targets: [
        .executableTarget(
            name: "CalendarMenu",
            path: "Sources/CalendarMenu",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("EventKit"),
                .linkedFramework("SwiftUI")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
