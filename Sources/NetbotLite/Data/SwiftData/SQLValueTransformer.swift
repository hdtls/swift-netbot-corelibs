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

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import Foundation
  import HTTPTypes
  import NEAddressProcessing

  @available(SwiftStdlib 6.0, *)
  public class SQLValueTransformer<T: Codable>: ValueTransformer {

    public override class func transformedValueClass() -> AnyClass {
      NSData.self
    }

    public override class func allowsReverseTransformation() -> Bool {
      true
    }

    public override func transformedValue(_ value: Any?) -> Any? {
      guard let duration = value as? T else { return nil }
      return try? JSONEncoder().encode(duration)
    }

    public override func reverseTransformedValue(_ value: Any?) -> Any? {
      guard let data = value as? Data else { return nil }
      return try? JSONDecoder().decode(T.self, from: data)
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @available(SwiftStdlib 6.0, *)
  public func SQL_initialized() {
    ValueTransformer.setValueTransformer(
      SQLValueTransformer<Duration>(),
      forName: .init(rawValue: "SQLValueTransformer<Duration>")
    )
    ValueTransformer.setValueTransformer(
      SQLValueTransformer<Address>(),
      forName: .init(rawValue: "SQLValueTransformer<Address>")
    )
    ValueTransformer.setValueTransformer(
      SQLValueTransformer<HTTPFields>(),
      forName: .init(rawValue: "SQLValueTransformer<HTTPFields>")
    )
    ValueTransformer.setValueTransformer(
      SQLValueTransformer<HTTPRequest>(),
      forName: .init(rawValue: "SQLValueTransformer<HTTPRequest>")
    )
    ValueTransformer.setValueTransformer(
      SQLValueTransformer<HTTPResponse>(),
      forName: .init(rawValue: "SQLValueTransformer<HTTPResponse>")
    )
  }
#endif
