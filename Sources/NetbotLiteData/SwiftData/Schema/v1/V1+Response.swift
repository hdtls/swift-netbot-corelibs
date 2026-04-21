// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2024 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import HTTPTypes

#if canImport(Darwin) || swift(>=6.3)
  import Observation
#endif

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(SwiftData) && NETBOT_REQUIRES_PERSISTENT_STORAGE_SWIFTDATA
  import SwiftData
#endif

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension V1 {

  #if canImport(SwiftData) && NETBOT_REQUIRES_PERSISTENT_STORAGE_SWIFTDATA
    @Model final public class _Response {

      /// The HTTP request object if present. otherwise returns `nil`.
      public var httpResponse: HTTPResponse? {
        get {
          guard let _httpResponse else {
            return nil
          }
          return try? JSONDecoder().decode(HTTPResponse.self, from: _httpResponse)
        }
        set {
          guard let httpResponse = newValue else {
            _httpResponse = nil
            return
          }
          _httpResponse = try? JSONEncoder().encode(httpResponse)
        }
      }
      public var _httpResponse: Data?

      /// The data is sent as the message body of the request.
      @Attribute(.externalStorage)
      public var body: Data?

      public init() {}
    }
  #else
    #if canImport(Darwin) || swift(>=6.3)
      @Observable
    #endif
    final public class _Response {

      /// The HTTP request object if present. otherwise returns `nil`.
      public var httpResponse: HTTPResponse?

      /// The data is sent as the message body of the request.
      public var body: Data?

      public init() {}
    }
  #endif
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension V1._Response {

  /// Merge new values from data transfer object.
  /// - Parameter data: New `Response` to merge.
  public func mergeValues(_ data: Response) {
    #if swift(>=6.2) && !(canImport(SwiftData) && NETBOT_REQUIRES_PERSISTENT_STORAGE_SWIFTDATA)
      httpResponse = data.httpResponse
      body = data.body
    #else
      if httpResponse != data.httpResponse {
        httpResponse = data.httpResponse
      }
      if body != data.body {
        body = data.body
      }
    #endif
  }
}
