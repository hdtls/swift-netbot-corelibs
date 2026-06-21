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

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

/// A persistent representation of a request.
///
/// ``Request`` stores the request metadata, payload, and associated
/// connection information in a format suitable for persistence and
/// data transfer.
///
/// Use ``Request`` when working with requests in memory.
/// Use ``V1/Request`` when storing request data.
///
/// - SeeAlso: ``V1/Request``
@available(SwiftStdlib 6.0, *)
public struct Request: Codable, Hashable, Sendable {

  /// The HTTP request head.
  ///
  /// Contains the request method, target URI, version,
  /// and request header fields.
  ///
  /// - Important: Modify `httpRequest` also change `address`.
  public var httpRequest: HTTPRequest? {
    didSet {
      address = httpRequest?.address
    }
  }

  /// The destination address associated with the request.
  ///
  /// This value typically identifies the remote endpoint to which
  /// the request was sent.
  public var address: Address?

  /// The request body payload.
  ///
  /// This value contains the raw bytes sent as part of the request.
  public var body: Data?

  /// The trailing HTTP fields sent after the request body.
  ///
  /// Trailer fields are commonly used with chunked transfer encoding
  /// to provide metadata that is only known after the body has been sent.
  public var trailerHTTPFields: HTTPFields?

  /// Create an instance of ``Request`` from `HTTPRequest`.
  /// - Parameter httpRequest: Original HTTP request.
  package init(httpRequest: HTTPRequest) {
    self.httpRequest = httpRequest
    self.address = httpRequest.address
  }

  /// Create an instance of ``Request`` from ``NEAddressProcessing/Address``.
  /// - Parameter address: Request address.
  package init(address: Address) {
    self.address = address
  }

  /// Returns the host component of the Request if present, otherwise returns `nil`.
  ///
  /// - Parameter percentEncoded: Whether the host should be percent encoded,
  ///   defaults to `true`.
  /// - Returns: The host component of the Request
  public func host(percentEncoded: Bool = true) -> String? {
    guard let host = address?.host(percentEncoded: percentEncoded) else {
      return httpRequest?.host(percentEncoded: percentEncoded)
    }
    return host
  }

  /// Returns the port component of the Request if present, otherwise returns `nil`.
  public var port: Int? {
    guard let port = address?.port else {
      return httpRequest?.port
    }
    return port
  }
}

@available(SwiftStdlib 6.0, *)
extension Request {

  /// In used persistent model typealias.
  public typealias Model = V1.Request

  /// Create a new ``Request`` from persistent request.
  /// - Parameter persistentModel: Persistent request.
  public init(persistentModel: Model) {
    httpRequest = persistentModel.httpRequest
    address = persistentModel.address
    body = persistentModel.body
    trailerHTTPFields = persistentModel.trailerHTTPFields
  }
}

@available(SwiftStdlib 6.0, *)
extension HTTPRequest {

  /// Returns the host component of the HTTPRequest if present, otherwise returns `nil`.
  ///
  /// - Parameter percentEncoded: Whether the host should be percent encoded,
  ///   defaults to `true`.
  /// - Returns: The host component of the HTTPRequest
  public func host(percentEncoded: Bool = true) -> String? {
    guard let hostPart = authority?.split(separator: ":").first else {
      return nil
    }
    #if canImport(FoundationEssentials)
      let absoluteString = "\(scheme ?? "http")://\(hostPart)"
      return URL(string: absoluteString)?.host(percentEncoded: percentEncoded)
    #else
      guard percentEncoded else {
        return hostPart.removingPercentEncoding
      }
      return hostPart.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
    #endif
  }

  /// Returns the port component of the HTTPRequest if present, otherwise returns `nil`.
  public var port: Int? {
    guard let portString = authority?.split(separator: ":").last else {
      return nil
    }
    return Int(portString)
  }

  /// Returns the address component of the HTTPRequest if present, otherwise returns `nil`.
  public var address: Address? {
    guard let hostString = host(percentEncoded: false), let port else {
      return nil
    }
    return .hostPort(host: .init(hostString), port: .init(rawValue: UInt16(port)))
  }
}
