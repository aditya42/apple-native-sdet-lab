// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ContactDomain",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "ContactDomain", targets: ["ContactDomain"])
    ],
    targets: [
        .target(name: "ContactDomain"),
        .testTarget(name: "ContactDomainTests", dependencies: ["ContactDomain"])
    ]
)
