// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// See LICENSE.txt for license information
//

import CompilerPluginSupport
import PackageDescription

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

var swiftSettings: [SwiftSetting] = [
  .enableExperimentalFeature("AccessLevelOnImport"),
  .enableUpcomingFeature("InternalImportsByDefault"),
  .define("EXTENDED_ALL"),
  .define("ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING"),
]

if Context.environment["ENABLE_NIO_POSIX"] == nil {
  swiftSettings += [.define("ENABLE_NIO_TRANSPORT_SERVICES")]
}

var dependencies: [Package.Dependency] = [
  .package(url: "https://github.com/apple/swift-asn1.git", from: "1.0.0"),
  .package(url: "https://github.com/apple/swift-certificates.git", from: "1.0.1"),
  .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
  .package(url: "https://github.com/apple/swift-http-types", from: "1.0.0"),
  .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2"),
  .package(url: "https://github.com/apple/swift-nio.git", from: "2.32.1"),
  .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.14.1"),
  .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
]

if Context.environment["ENABLE_LOCAL_PACKAGE_DEPENDENCIES"] == nil {
  dependencies += [
    .package(url: "https://github.com/hdtls/swift-netbot-essentials.git", branch: "main"),
    .package(url: "https://github.com/hdtls/swift-maxminddb.git", from: "1.2.1"),
    .package(url: "https://github.com/hdtls/swift-preference.git", from: "1.0.0"),
  ]
} else {
  dependencies += [
    .package(path: "../swift-netbot-essentials"),
    .package(path: "../swift-maxminddb"),
    .package(path: "../swift-preference"),
  ]
}

let package = Package(
  name: "swift-netbot-corelibs",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
    .tvOS(.v17),
  ],
  products: [
    .library(name: "Netbot", targets: ["Netbot"]),
    .library(name: "NetbotUI", targets: ["NetbotUI"]),
    .library(name: "Dashboard", targets: ["Dashboard"]),
    .library(name: "DashboardUI", targets: ["DashboardUI"]),
    .library(name: "_NEAnalytics", targets: ["_NEAnalytics"]),
    .library(name: "NEXPCService", targets: ["NEXPCService"]),
  ],
  dependencies: dependencies,
  targets: [
    .binaryTarget(
      name: "tun2proxy",
      url:
        "https://github.com/tun2proxy/tun2proxy/releases/download/v0.6.6/tun2proxy-apple-xcframework.zip",
      checksum: "dcc7f5ec4b2def6ebf9582eb432f4e388c8ce2481b621e95f382934781a2c666"
    ),
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
        "_PersistentStore",
        "_ResourceProcessing",
        "CNELwIP",
        "CNETTP",
        .product(name: "Anlzr", package: "swift-netbot-essentials"),
        .product(name: "MaxMindDB", package: "swift-maxminddb"),
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NIOSSL", package: "swift-nio-ssl"),
        .product(name: "Preference", package: "swift-preference"),
        .product(name: "X509", package: "swift-certificates"),
      ],
      swiftSettings: swiftSettings
    ),
    .target(
      name: "_PersistentStore",
      dependencies: [
        .product(name: "Logging", package: "swift-log"),
        .product(name: "Preference", package: "swift-preference"),
      ],
      swiftSettings: swiftSettings
    ),
    .target(
      name: "_ResourceProcessing",
      dependencies: [
        .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(name: "Logging", package: "swift-log"),
      ],
      swiftSettings: swiftSettings
    ),
    .target(
      name: "CNELwIP",
      exclude: privacyManifestExclude + [
        "hash.txt"
      ],
      resources: privacyManifestResource,
      cSettings: [
        .headerSearchPath("opt"),
        .headerSearchPath("include"),
        .define("LWIP_DEBUG", .when(configuration: .debug)),
      ]
    ),
    .target(
      name: "CNETTP",
      dependencies: [
        "tun2proxy"
      ]
    ),
    .target(
      name: "Dashboard",
      dependencies: [
        "_PersistentStore",
        .product(name: "AnlzrReports", package: "swift-netbot-essentials"),
      ],
      swiftSettings: swiftSettings
    ),
    .target(name: "DashboardUI", dependencies: ["Dashboard"], swiftSettings: swiftSettings),
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
      ],
      swiftSettings: swiftSettings
    ),
    .target(
      name: "NetbotUI",
      dependencies: ["Netbot"]
    ),
    .target(name: "NEXPCService"),
    .testTarget(
      name: "_NEAnalyticsTests",
      dependencies: ["_NEAnalytics"],
      exclude: [
        "External Resource/4a79917602f5e63d3fb28166ded4b8f5",
        "External Resource/24e84f0f66c2bcd5582519b4a76f2ffe",
      ],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "_ResourceProcessingTests",
      dependencies: ["_ResourceProcessing"],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "NetbotTests",
      dependencies: ["Netbot"],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "NetbotMacrosTests",
      dependencies: [
        "NetbotMacros",
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ]
    ),
  ]
)
