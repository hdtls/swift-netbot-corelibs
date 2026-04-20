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

#if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
  import HTTPTypes
  import NEAddressProcessing

  #if canImport(FoundationEssentials)
    import FoundationEssentials
  #else
    import Foundation
  #endif

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension V1 {

    public struct _HTTPRequest: Codable, Equatable, Hashable {

      var method: HTTPRequest.Method {
        guard
          let rawValue = pseudoHeaderFields.first(where: { $0.name.rawName == ":method" })?.value
        else {
          return .connect
        }
        return .init(rawValue: rawValue) ?? .connect
      }

      var scheme: String? {
        pseudoHeaderFields.first(where: { $0.name.rawName == ":scheme" })?.value
      }

      var authority: String? {
        pseudoHeaderFields.first(where: { $0.name.rawName == ":authority" })?.value
      }

      var path: String? {
        pseudoHeaderFields.first(where: { $0.name.rawName == ":path" })?.value
      }

      var extendedConnectProtocol: String? {
        pseudoHeaderFields.first(where: { $0.name.rawName == ":protocol" })?.value
      }

      /// The pseudo header fields.
      public var pseudoHeaderFields: [HTTPField]

      /// The request header fields.
      public var headerFields: [HTTPField]

      init(httpRequest: HTTPRequest) {
        var pseudoHeaderFields: [HTTPField] = [httpRequest.pseudoHeaderFields.method]
        if let scheme = httpRequest.pseudoHeaderFields.scheme {
          pseudoHeaderFields.append(scheme)
        }
        if let authority = httpRequest.pseudoHeaderFields.authority {
          pseudoHeaderFields.append(authority)
        }
        if let path = httpRequest.pseudoHeaderFields.path {
          pseudoHeaderFields.append(path)
        }
        if let extendedConnectProtocol = httpRequest.pseudoHeaderFields.extendedConnectProtocol {
          pseudoHeaderFields.append(extendedConnectProtocol)
        }

        self.pseudoHeaderFields = pseudoHeaderFields
        self.headerFields = Array(httpRequest.headerFields)
      }

      enum CodingKeys: String, CodingKey {
        case pseudoHeaderFields
        case headerFields
      }

      public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: V1._HTTPRequest.CodingKeys.self)
        self.pseudoHeaderFields = try container.decode(
          [HTTPField].self, forKey: .pseudoHeaderFields)
        self.headerFields = try container.decode([HTTPField].self, forKey: .headerFields)
      }

      public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: V1._HTTPRequest.CodingKeys.self)
        try container.encode(pseudoHeaderFields, forKey: .pseudoHeaderFields)
        try container.encode(headerFields, forKey: .headerFields)
      }
    }

    #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    public struct _HTTPResponse: Codable, Equatable {

      public var headerFields: [HTTPField]

      public var pseudoHeaderFields: [HTTPField]

      public var reasonPhrase: String

      init(httpResponse: HTTPResponse) {
        var fieldValue: String {
          if #available(SwiftStdlib 5.3, *) {
            return String(unsafeUninitializedCapacity: 3) { buffer in
              buffer[0] = UInt8(httpResponse.status.code / 100) + 48
              buffer[1] = UInt8((httpResponse.status.code / 10) % 10) + 48
              buffer[2] = UInt8(httpResponse.status.code % 10) + 48
              return 3
            }
          } else {
            return String([
              Character(Unicode.Scalar(UInt8(httpResponse.status.code / 100) + 48)),
              Character(Unicode.Scalar(UInt8((httpResponse.status.code / 10) % 10) + 48)),
              Character(Unicode.Scalar(UInt8(httpResponse.status.code % 10) + 48)),
            ])
          }
        }

        headerFields = Array(httpResponse.headerFields)
        pseudoHeaderFields = [HTTPField(name: .init(parsed: ":status")!, value: fieldValue)]
        reasonPhrase = httpResponse.status.reasonPhrase
      }

      enum CodingKeys: String, CodingKey {
        case headerFields
        case pseudoHeaderFields
        case reasonPhrase
      }

      public init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<V1._HTTPResponse.CodingKeys> =
          try decoder.container(
            keyedBy: V1._HTTPResponse.CodingKeys.self)
        self.headerFields = try container.decode(
          [HTTPField].self, forKey: .headerFields)
        self.pseudoHeaderFields = try container.decode(
          [HTTPField].self, forKey: .pseudoHeaderFields)
        self.reasonPhrase = try container.decode(String.self, forKey: .reasonPhrase)
      }

      public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: V1._HTTPResponse.CodingKeys.self)
        try container.encode(headerFields, forKey: .headerFields)
        try container.encode(pseudoHeaderFields, forKey: .pseudoHeaderFields)
        try container.encode(reasonPhrase, forKey: .reasonPhrase)
      }
    }
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension HTTPRequest {

    public typealias Model = V1._HTTPRequest

    public init(persistentModel: Model) {
      self.init(
        method: persistentModel.method,
        scheme: persistentModel.scheme,
        authority: persistentModel.authority,
        path: persistentModel.path,
        headerFields: .init(persistentModel.headerFields)
      )
      extendedConnectProtocol = persistentModel.extendedConnectProtocol
    }
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension HTTPResponse {

    public typealias Model = V1._HTTPResponse

    public init(persistentModel: Model) {
      self.init(
        status: .init(
          code: Int(persistentModel.pseudoHeaderFields.first!.value)!,
          reasonPhrase: persistentModel.reasonPhrase),
        headerFields: HTTPFields(persistentModel.headerFields)
      )
    }
  }
#endif

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension Duration {
  var seconds: Double {
    let (seconds, attoseconds) = components
    return Double(seconds) + Double(attoseconds) / 1_000_000_000_000_000_000
  }
}
