// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

import Foundation
import NetbotProfile

/// Duplicate a new object.
#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public protocol Duplicable {

  /// Make a copy.
  func copy() -> Self
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension Sequence where Element: Duplicable {

  /// Make a duplicate element.
  ///
  /// This method will make a copy of `elementToDuplicate` and change the value of `name` keyPath to a new value.
  ///
  /// e.g. If original element value of name keyPath is `discussion` then the duplicated element value of name keyPath
  /// will be change to `discussion copy` or `discussion copy 1` if there already contains a element whitch
  /// `name` keyPath value is `discussion copy`.
  ///
  /// - Parameters:
  ///   - elementToDuplicate: The element to duplicate.
  ///   - name: The name keyPath identifier duplicated element.
  /// - Returns: Duplicated element.
  public func duplicate(_ elementToDuplicate: Element, name: WritableKeyPath<Element, String>)
    -> Element
  {
    let prefix = "\(elementToDuplicate[keyPath: name]) copy"
    let names = self.lazy
      .filter { $0[keyPath: name].hasPrefix(prefix) }
      .map {
        $0[keyPath: name]
          .replacingOccurrences(of: prefix, with: "")
          .trimmingCharacters(in: .whitespaces)
      }
      .map { $0.isEmpty ? "0" : $0 }
      .sorted()

    // Found missing name.
    var missing = 0
    for name in names {
      guard name == String(missing) else {
        break
      }
      missing += 1
    }

    var copy = elementToDuplicate.copy()
    copy[keyPath: name] =
      "\(elementToDuplicate[keyPath: name]) copy\(missing == 0 ? "" : " \(missing)")"
    return copy
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension Sequence where Element == String {

  /// Make a duplicate element.
  ///
  /// This method will make a copy of `elementToDuplicate` and change the value of `name` keyPath to a new value.
  ///
  /// e.g. If original element value of name keyPath is `discussion` then the duplicated element value of name keyPath
  /// will be change to `discussion copy` or `discussion copy 1` if there already contains a element whitch
  /// `name` keyPath value is `discussion copy`.
  ///
  /// - Parameters:
  ///   - elementToDuplicate: The element to duplicate.
  /// - Returns: Duplicated element.
  public func duplicate(_ elementToDuplicate: Element) -> Element {
    let prefix = "\(elementToDuplicate) copy"
    let names = self.lazy
      .filter { $0.hasPrefix(prefix) }
      .map {
        $0
          .replacingOccurrences(of: prefix, with: "")
          .trimmingCharacters(in: .whitespaces)
      }
      .map { $0.isEmpty ? "0" : $0 }
      .sorted()

    // Found missing name.
    var missing = 0
    for name in names {
      guard name == String(missing) else {
        break
      }
      missing += 1
    }

    let finalize = "\(elementToDuplicate) copy\(missing == 0 ? "" : " \(missing)")"
    return finalize
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_7
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension NetbotProfile.V1._AnyProxy {

  public func copy() -> NetbotProfile.V1._AnyProxy {
    let duplicated = NetbotProfile.V1._AnyProxy()
    duplicated.name = lazyProfile?.lazyProxies.map(\.name).duplicate(name) ?? name
    duplicated.source = source
    duplicated.kind = kind
    duplicated.serverAddress = serverAddress
    duplicated.port = port
    duplicated.username = username
    duplicated.passwordReference = passwordReference
    duplicated.alpn = alpn
    duplicated.authenticationRequired = authenticationRequired
    duplicated.algorithm = algorithm
    duplicated.obfuscation = obfuscation
    duplicated.measurePolicy = measurePolicy
    duplicated.transactionMetrics = .init()
    duplicated.tls = tls
    duplicated.ws = ws
    duplicated.engress = engress
    duplicated.allowUDPRelay = allowUDPRelay
    duplicated.isTFOEnabled = isTFOEnabled
    duplicated.forceHTTPTunneling = forceHTTPTunneling
    duplicated.dontAlertError = dontAlertError
    duplicated.lazyProfile = lazyProfile
    return duplicated
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_7
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension NetbotProfile.V1._AnyProxyGroup {

  public func copy() -> NetbotProfile.V1._AnyProxyGroup {
    let duplicated = NetbotProfile.V1._AnyProxyGroup()
    duplicated.name = lazyProfile?.lazyProxyGroups.map(\.name).duplicate(name) ?? name
    duplicated.kind = kind
    duplicated.resource = resource
    duplicated.measurePolicy = measurePolicy
    duplicated.transactionMetrics = .init()
    duplicated.lazyProfile = lazyProfile
    duplicated.lazyProxies = lazyProxies
    return duplicated
  }
}
