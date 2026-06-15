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

/// A `Request` object represents a proxy load request.
@available(SwiftStdlib 6.0, *)
public struct Request: Codable, Hashable, Sendable {

  /// The HTTP request object if present. otherwise returns `nil`.
  public var httpRequest: HTTPRequest? {
    didSet {
      address = httpRequest?.address
    }
  }

  /// The address of the receiver.
  public var address: Address?

  /// The data is sent as the message body of the request.
  public var body: Data?

  /// The HTTP message trailer headers (Trailer / chunked encoding).
  public var trailers: HTTPFields?

  package init(httpRequest: HTTPRequest) {
    self.httpRequest = httpRequest
    self.address = httpRequest.address
  }

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

  public typealias Model = V1._Request

  public init(persistentModel: Model) {
    httpRequest = persistentModel.httpRequest
    address = persistentModel.address
    body = persistentModel.body
    trailers = persistentModel.trailers
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
