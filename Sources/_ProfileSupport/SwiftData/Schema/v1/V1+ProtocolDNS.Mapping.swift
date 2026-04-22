// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(SwiftData)
  import SwiftData
#endif

#if swift(>=6.3)
  import Observation
#endif

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension V1 {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  public enum _ProtocolDNS {}
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension V1._ProtocolDNS {

  /// An object declaring DNS mappings.
  #if canImport(SwiftData)
    @Model
  #else
    #if swift(>=6.3)
      @Observable
    #endif
  #endif
  public class _Mapping {

    /// A boolean value determinse whether this mapping is enabled.
    public var isEnabled = true

    /// The strategy of the mapping.
    public var strategy = ProtocolDNS.MappingStrategy.mapping

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
    public var lazyProfile: V1._Profile?

    public init() {
    }
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension V1._ProtocolDNS._Mapping {

  public func mergeValues(_ data: ProtocolDNS.Mapping) {
    isEnabled = data.isEnabled
    strategy = data.strategy
    domainName = data.domainName
    value = data.value
    note = data.note
    creationDate = data.creationDate
  }
}
