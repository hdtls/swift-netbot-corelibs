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
  import HTTPTypes
  import Foundation
  import SwiftData
  import _ProfileSupport

  @available(SwiftStdlib 5.9, *)
  extension V1 {

    @Model public class _StubbedHTTPResponse {

      /// A boolean value determinse whether this rule is enabled or disabled.
      public var isEnabled = true

      /// Incoming request URL matching pattern.
      public var pattern = ""

      /// Response body content URL.
      public var bodyContentsURL: URL?

      /// Response status code.
      public var statusCode = 200

      /// Response status reason phrase.
      public var reasonPhrase = ""

      /// Additional HTTP fields for stubbed response.
      public var additionalHTTPFields = HTTPFields()

      /// The time the resource was created.
      public var creationDate = Date.now

      /// Relationship with `_Profile`.
      public var lazyProfile: _Profile?

      public init() {
      }
    }
  }

  @available(SwiftStdlib 5.9, *)
  extension StubbedHTTPResponse {

    public typealias PersistentModel = V1._StubbedHTTPResponse

    public init(persistentModel: PersistentModel) {
      self.init()
      isEnabled = persistentModel.isEnabled
      pattern = persistentModel.pattern
      bodyContentsURL = persistentModel.bodyContentsURL
      status = .init(
        code: persistentModel.statusCode,
        reasonPhrase: persistentModel.reasonPhrase
      )
      additionalHTTPFields = persistentModel.additionalHTTPFields
      creationDate = persistentModel.creationDate
    }
  }

  @available(SwiftStdlib 5.9, *)
  extension V1._StubbedHTTPResponse {
    public func mergeValues(_ data: StubbedHTTPResponse) {
      isEnabled = data.isEnabled
      pattern = data.pattern
      bodyContentsURL = data.bodyContentsURL
      statusCode = data.status.code
      reasonPhrase = data.status.reasonPhrase
      additionalHTTPFields = data.additionalHTTPFields
      creationDate = data.creationDate
    }
  }
#endif
