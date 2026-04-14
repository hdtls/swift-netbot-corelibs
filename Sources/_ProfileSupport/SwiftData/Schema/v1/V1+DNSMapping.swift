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

#if canImport(SwiftData)
  import Foundation
  import SwiftData

  @available(SwiftStdlib 5.9, *)
  extension V1 {

    /// An Object declaring DNS mapping rules.
    @Model public class _DNSMapping {

      /// A boolean value determinse whether this mapping is enabled.
      public var isEnabled = true

      public typealias Kind = DNSMapping.Kind

      /// The kind of the mapping.
      public var kind = Kind.mapping

      /// The domain to perform local DNS mapping.
      public var domainName = ""

      /// The mapped value.
      ///
      /// When the `kind` value is `mapping`, the value represents the mapped IP address.
      /// When the `kind` value is `cname`, the value represents the mapped new domain name.
      /// When the `kind` value is `dns`, the value represents the new domain name resolution server.
      public var value = ""

      /// The note on this DNS mapping.
      public var note = ""

      /// The date when the mapping created.
      public var creationDate = Date.now

      /// Relationship with `_Profile`.
      public var lazyProfile: _Profile?

      public init() {
      }
    }
  }

  @available(SwiftStdlib 5.9, *)
  extension DNSMapping {

    public typealias PersistentModel = V1._DNSMapping

    public init(persistentModel: PersistentModel) {
      self.init()
      isEnabled = persistentModel.isEnabled
      kind = persistentModel.kind
      domainName = persistentModel.domainName
      value = persistentModel.value
      note = persistentModel.note
      creationDate = persistentModel.creationDate
    }
  }

  @available(SwiftStdlib 5.9, *)
  extension V1._DNSMapping {

    public func mergeValues(_ data: DNSMapping) {
      isEnabled = data.isEnabled
      kind = data.kind
      domainName = data.domainName
      value = data.value
      note = data.note
      creationDate = data.creationDate
    }
  }
#endif
