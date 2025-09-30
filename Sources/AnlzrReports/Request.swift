//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

import Foundation
import HTTPTypes
import NEAddressProcessing

/// A `Request` object represents a proxy load request.
@available(SwiftStdlib 5.3, *)
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

  public init(httpRequest: HTTPRequest) {
    self.httpRequest = httpRequest
    self.address = httpRequest.address
  }

  public init(address: Address) {
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

#if swift(>=6.3) || canImport(Darwin)
  @available(SwiftStdlib 5.9, *)
  extension Request {

    public typealias PersistentModel = V1._Request

    public init(persistentModel: PersistentModel) {
      httpRequest = persistentModel.httpRequest
      address = persistentModel.address
      body = persistentModel.body
    }
  }
#endif

@available(SwiftStdlib 5.3, *)
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
    guard percentEncoded else {
      return hostPart.removingPercentEncoding
    }
    return hostPart.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
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
