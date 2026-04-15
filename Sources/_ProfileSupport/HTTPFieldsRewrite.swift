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

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

/// A HTTP fields modification representation object, define how to modify mached request header fields.
@available(SwiftStdlib 5.3, *)
public struct HTTPFieldsRewrite: Equatable, Hashable, Sendable {

  /// An enum define HTTP directions.
  public enum Direction: String, CaseIterable, Codable, Hashable, Sendable {
    case request
    case response
  }

  /// An enum define modification actions.
  public enum Action: String, CaseIterable, Codable, Hashable, Sendable {
    case add
    case remove
    case replace

    @available(SwiftStdlib 5.5, *)
    public var localizedName: String {
      switch self {
      #if canImport(Darwin)
        case .add: String(localized: "Add HTTP Field")
        case .remove: String(localized: "Delete HTTP Field")
        case .replace: String(localized: "Replace HTTP Field")
      #else
        case .add: "Add HTTP Field"
        case .remove: "Delete HTTP Field"
        case .replace: "Replace HTTP Field"
      #endif
      }
    }
  }

  /// A boolean value determinse whether this rule is enabled or disabled.
  public var isEnabled = true

  /// Direction of HTTP communication.
  public var direction = Direction.request

  /// Incoming request URL matching pattern.
  public var pattern: String

  /// Action for modification.
  public var action: Action

  /// HTTP header field name.
  public var name: String

  /// The value of the rewrite definition.
  public var value = ""

  /// A regex describing the field value to replace.
  public var replacement = ""

  /// The time the resource was created.
  public var creationDate: Date

  /// Create a `HTTPFieldsRewrite` with specified values.
  public init(
    isEnabled: Bool = true,
    direction: Direction = .request,
    pattern: String = "",
    action: Action = .add,
    name: String = "",
    replacement: String = "",
    value: String = ""
  ) {
    self.isEnabled = isEnabled
    self.direction = direction
    self.pattern = pattern
    self.action = action
    self.name = name
    self.replacement = replacement
    self.value = value
    if #available(SwiftStdlib 5.5, *) {
      self.creationDate = .now
    } else {
      self.creationDate = .init()
    }
  }
}

@available(SwiftStdlib 5.9, *)
extension HTTPFieldsRewrite {

  public typealias Model = V1._HTTPFieldsRewrite

  public init(persistentModel: Model) {
    self.init()
    isEnabled = persistentModel.isEnabled
    direction = persistentModel.direction
    pattern = persistentModel.pattern
    action = persistentModel.action
    name = persistentModel.name
    replacement = persistentModel.replacement
    value = persistentModel.value
    creationDate = persistentModel.creationDate
  }
}
