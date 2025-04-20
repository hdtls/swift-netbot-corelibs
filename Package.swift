// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// See LICENSE.txt for license information
//

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-netbot-corelibs",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
    .tvOS(.v17),
  ],
  products: [
    .library(name: "Netbot", targets: ["Netbot"]),
    .library(name: "Dashboard", targets: ["Dashboard"]),
    .library(name: "DashboardUI", targets: ["DashboardUI"]),
    .library(name: "_NEAnalytics", targets: ["_NEAnalytics"]),
    .library(name: "NEXPCService", targets: ["NEXPCService"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-asn1.git", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-certificates.git", from: "1.0.1"),
    .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
    .package(url: "https://github.com/apple/swift-http-types", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2"),
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.32.1"),
    .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.14.1"),
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
    .package(url: "https://github.com/hdtls/swift-netbot-frame-processing.git", branch: "main"),
    .package(url: "https://github.com/hdtls/swift-netbot-essentials.git", branch: "main"),
    .package(url: "https://github.com/hdtls/swift-maxminddb.git", from: "1.2.1"),
    .package(url: "https://github.com/hdtls/swift-preference.git", from: "1.0.0"),
  ],
  targets: [
    .macro(
      name: "NetbotMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "_NEAnalytics",
      dependencies: [
        "_PrettyDNS",
        "_PersistentStore",
        "_ResourceProcessing",
        .product(name: "Anlzr", package: "swift-netbot-essentials"),
        .product(name: "MaxMindDB", package: "swift-maxminddb"),
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NIOSSL", package: "swift-nio-ssl"),
        .product(name: "Preference", package: "swift-preference"),
        .product(name: "X509", package: "swift-certificates"),
      ]
    ),
    .target(
      name: "_PersistentStore",
      dependencies: [
        .product(name: "Logging", package: "swift-log"),
        .product(name: "Preference", package: "swift-preference"),
      ]
    ),
    .target(
      name: "_PrettyDNS",
      dependencies: [
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NEAddressProcessing", package: "swift-netbot-frame-processing"),
      ]
    ),
    .target(
      name: "_ResourceProcessing",
      dependencies: [
        .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(name: "Logging", package: "swift-log"),
      ]
    ),
    .target(
      name: "Dashboard",
      dependencies: [
        "_PersistentStore",
        .product(name: "AnlzrReports", package: "swift-netbot-essentials"),
      ]
    ),
    .target(name: "DashboardUI", dependencies: ["Dashboard"]),
    .target(
      name: "Netbot",
      dependencies: [
        "NetbotMacros",
        "_PersistentStore",
        "_ResourceProcessing",
        .product(name: "_CryptoExtras", package: "swift-crypto"),
        .product(name: "Crypto", package: "swift-crypto"),
        .product(name: "NIOSSL", package: "swift-nio-ssl"),
        .product(name: "Preference", package: "swift-preference"),
        .product(name: "SwiftASN1", package: "swift-asn1"),
        .product(name: "X509", package: "swift-certificates"),
      ]
    ),
    .target(name: "NEXPCService"),
    .testTarget(
      name: "_NEAnalyticsTests",
      dependencies: ["_NEAnalytics"],
      exclude: ["External Resource"]
    ),
    .testTarget(name: "_PrettyDNSTests", dependencies: ["_PrettyDNS"]),
    .testTarget(name: "_ResourceProcessingTests", dependencies: ["_ResourceProcessing"]),
    .testTarget(name: "NetbotTests", dependencies: ["Netbot"]),
    .testTarget(
      name: "NetbotMacrosTests",
      dependencies: [
        "NetbotMacros",
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ]
    ),
  ]
)

#if canImport(Darwin)
  // This doesn't work when cross-compiling: the privacy manifest will be included in the Bundle and
  // Foundation will be linked. This is, however, strictly better than unconditionally adding the
  // resource.
  #if canImport(Darwin)
    let privacyManifestExclude: [String] = []
    let privacyManifestResource: [PackageDescription.Resource] = [.copy("PrivacyInfo.xcprivacy")]
  #else
    // Exclude on other platforms to avoid build warnings.
    let privacyManifestExclude: [String] = ["PrivacyInfo.xcprivacy"]
    let privacyManifestResource: [PackageDescription.Resource] = []
  #endif

  // There is some issues that make CNELwIP unavailable on non-Darwin platform.
  package.targets.append(
    .target(
      name: "CNELwIP",
      exclude: privacyManifestExclude + [
        "hash.txt"
      ],
      resources: privacyManifestResource,
      cSettings: [
        // Debugging options
        .define("LWIP_DEBUG", to: "1", .when(configuration: .debug)),

        .headerSearchPath("opt"),
        .headerSearchPath("include"),
      ]
    )
  )
  package.targets.first(where: { $0.name == "_NEAnalytics" })?.dependencies.append("CNELwIP")
#endif

for target in package.targets {
  var settings = target.swiftSettings ?? []
  settings.append(.define("EXTENDED_ALL"))
  settings.append(.define("ENABLE_NIO_TRANSPORT_SERVICES"))
  target.swiftSettings = settings
}

for target in package.targets {
  switch target.type {
  case .regular, .test, .executable:
    var settings = target.swiftSettings ?? []
    // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0444-member-import-visibility.md
    settings.append(.enableUpcomingFeature("MemberImportVisibility"))
    target.swiftSettings = settings
  case .macro, .plugin, .system, .binary:
    ()  // not applicable
  @unknown default:
    ()  // we don't know what to do here, do nothing
  }
}
