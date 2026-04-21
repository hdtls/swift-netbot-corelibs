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
import NEAddressProcessing

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
    @Model final public class _Request {

      /// The HTTP request object if present. otherwise returns `nil`.
      public var httpRequest: HTTPRequest? {
        get {
          guard let _httpRequest else {
            return nil
          }
          return try? JSONDecoder().decode(HTTPRequest.self, from: _httpRequest)
        }
        set {
          guard let httpRequest = newValue else {
            _httpRequest = nil
            return
          }
          _httpRequest = try? JSONEncoder().encode(httpRequest)
        }
      }
      public var _httpRequest: Data?

      /// The address of the receiver.
      public var address: Address? {
        get {
          guard let _address else { return nil }
          return try? JSONDecoder().decode(Address.self, from: _address)
        }
        set {
          guard let address = newValue else {
            _address = nil
            return
          }
          _address = try? JSONEncoder().encode(address)
        }
      }
      public var _address: Data?

      /// The host of the receiver.
      public var hostname: String?

      /// The URL string of the receiver.
      public var absoluteURLString: String?

      /// The data is sent as the message body of the request.
      @Attribute(.externalStorage) public var body: Data?

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

      /// The host of the receiver.
      public var hostname: String?

      /// The URL string of the receiver.
      public var absoluteURLString: String?

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
extension V1._Request {

  /// Merge new values from data transfer object.
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

    #if swift(>=6.2) && !(canImport(SwiftData) && NETBOT_REQUIRES_PERSISTENT_STORAGE_SWIFTDATA)
      self.httpRequest = data.httpRequest
      self.address = data.address
      self.hostname = data.host(percentEncoded: false)
      self.absoluteURLString = absoluteURLString
      self.body = data.body
    #else
      #if canImport(SwiftData) && NETBOT_REQUIRES_PERSISTENT_STORAGE_SWIFTDATA
        if let httpRequest = data.httpRequest {
          let _httpRequest = try? JSONEncoder().encode(httpRequest)
          if self._httpRequest != _httpRequest {
            self._httpRequest = _httpRequest
          }
        }
        if let address = data.address {
          let _address = try? JSONEncoder().encode(address)
          if self._address != _address {
            self._address = _address
          }
        }
      #else
        if self.httpRequest != data.httpRequest {
          self.httpRequest = data.httpRequest
        }
        if self.address != data.address {
          self.address = data.address
        }
      #endif

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
