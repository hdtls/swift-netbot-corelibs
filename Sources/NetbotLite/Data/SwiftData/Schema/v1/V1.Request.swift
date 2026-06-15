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

import HTTPTypes
import NEAddressProcessing

#if canImport(Darwin) || swift(>=6.3)
  import Observation
#endif

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import SwiftData
#endif

@available(SwiftStdlib 6.0, *)
extension V1 {

  #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
    @Model final public class _Request {

      /// The HTTP request object if present. otherwise returns `nil`.
      @Attribute(.transformable(by: SQLValueTransformer<HTTPRequest>.self))
      public var httpRequest: HTTPRequest?

      /// The address of the receiver.
      @Attribute(.transformable(by: SQLValueTransformer<Address>.self))
      public var address: Address?

      /// The HTTP message trailer headers (Trailer / chunked encoding).
      @Attribute(.transformable(by: SQLValueTransformer<HTTPFields>.self))
      public var trailers: HTTPFields?

      /// The host of the receiver.
      public var hostname: String?

      /// The URL string of the receiver.
      public var absoluteURLString: String?

      /// The data is sent as the message body of the request.
      @Attribute(.externalStorage) public var body: Data?

      public var connection: _Connection?

      public init() {}
    }
  #else
    #if canImport(Darwin) || swift(>=6.3)
      @Observable
    #endif
    final public class _Request {

      /// The HTTP request object if present. otherwise returns `nil`.
      public var httpRequest: HTTPRequest?

      /// The address of the receiver.
      public var address: Address?

      /// The HTTP message trailer headers (Trailer / chunked encoding).
      public var trailers: HTTPFields?

      /// The host of the receiver.
      public var hostname: String?

      /// The URL string of the receiver.
      public var absoluteURLString: String?

      /// The data is sent as the message body of the request.
      public var body: Data?

      public var connection: _Connection?

      public init() {}
    }
  #endif
}

@available(SwiftStdlib 6.0, *)
extension V1._Request {

  /// Merge new values from DTO.
  /// - Parameter data: New `Request` to merge.
  public func mergeValues(_ data: Request) {
    var absoluteURLString = ""
    if let host = data.host(percentEncoded: false) {
      var portString = ""
      if let port = data.port {
        if port != 80 && port != 443 {
          portString = ":\(port)"
        }
      }

      if var path = data.httpRequest?.path, !path.isEmpty {
        path = path.hasPrefix("/") ? path : "/\(path)"
        path = path.last == "/" ? String(path.dropLast(1)) : path
        absoluteURLString = "\(host)\(portString)\(path)"
      } else {
        absoluteURLString = "\(host)\(portString)"
      }
    }

    #if swift(>=6.2) && !(canImport(SwiftData) && SWTNE_REQUIRES_SQL)
      self.httpRequest = data.httpRequest
      self.address = data.address
      self.trailers = data.trailers
      self.body = data.body
      self.hostname = data.host(percentEncoded: false)
      self.absoluteURLString = absoluteURLString
    #else
      if self.httpRequest != data.httpRequest {
        self.httpRequest = data.httpRequest
      }
      if self.address != data.address {
        self.address = data.address
      }
      if self.trailers != data.trailers {
        self.trailers = data.trailers
      }
      if self.hostname != data.host(percentEncoded: false) {
        self.hostname = data.host(percentEncoded: false)
      }
      if self.absoluteURLString != absoluteURLString {
        self.absoluteURLString = absoluteURLString
      }
      if self.body != data.body {
        self.body = data.body
      }
    #endif
  }
}
