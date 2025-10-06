//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

//#if canImport(FoundationEssentials)
//  import FoundationEssentials
//#else
import Foundation
import RegexBuilder

//#endif

/// Duplicate a new object.
@available(SwiftStdlib 5.3, *)
public protocol Duplicable {

  /// Make a copy.
  func copy() -> Self
}

@available(SwiftStdlib 5.3, *)
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

@available(SwiftStdlib 5.3, *)
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
