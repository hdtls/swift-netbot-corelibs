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
#else
  import NetbotSQL
#endif

@available(SwiftStdlib 6.0, *)
extension V1 {

  /// A persistent representation of a request.
  ///
  /// ``V1/Request`` stores the request metadata, payload, and associated
  /// connection information in a format suitable for persistence and
  /// data transfer.
  ///
  /// Use ``Request`` when working with requests in memory.
  /// Use ``V1/Request`` when storing request data.
  ///
  /// - SeeAlso: ``Request``
  @Model public class Request {

    /// The HTTP request head.
    ///
    /// Contains the request method, target URI, version,
    /// and request header fields.
    @Attribute(.transformable(by: SQLValueTransformer<HTTPRequest>.self))
    public var httpRequest: HTTPRequest?

    /// The destination address associated with the request.
    ///
    /// This value typically identifies the remote endpoint to which
    /// the request was sent.
    @Attribute(.transformable(by: SQLValueTransformer<Address>.self))
    public var address: Address?

    /// The trailing HTTP fields sent after the request body.
    ///
    /// Trailer fields are commonly used with chunked transfer encoding
    /// to provide metadata that is only known after the body has been sent.
    @Attribute(.transformable(by: SQLValueTransformer<HTTPFields>.self))
    public var trailerHTTPFields: HTTPFields?

    /// The hostname associated with the request.
    ///
    /// This value may originate from the request target, DNS resolution,
    /// or the Host header field.
    public var hostname: String?

    /// The absolute URL string of the request.
    ///
    /// When available, this value contains the complete URL including
    /// the scheme, host, path, and query components.
    public var absoluteURLString: String?

    /// The request body payload.
    ///
    /// This value contains the raw bytes sent as part of the request.
    @Attribute(.externalStorage) public var body: Data?

    /// Information about the connection that carried the request.
    ///
    /// This value can be used to associate the request with a specific
    /// network connection and its recorded metadata.
    public var connection: V1.Connection?

    /// Creates an empty ``V1/Request`` record.
    public init() {}
  }
}

@available(SwiftStdlib 6.0, *)
extension V1.Request {

  /// Converts a runtime ``Request`` into a persistent ``V1/Request`` snapshot.
  ///
  /// This method captures the current state of the request at a point in time.
  /// Runtime-only fields (timers, live state transitions, observation locks)
  /// are flattened into persistable values.
  ///
  /// - Parameter data: New `Request` to map.
  public func mergeValues(_ data: NetbotLiteData.Request) {
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
      self.trailerHTTPFields = data.trailerHTTPFields
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
      if self.trailerHTTPFields != data.trailerHTTPFields {
        self.trailerHTTPFields = data.trailerHTTPFields
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
