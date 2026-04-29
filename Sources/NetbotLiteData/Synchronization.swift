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

#if canImport(Darwin) && NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  import NIOConcurrencyHelpers

  @available(SwiftStdlib 5.5, *)
  public typealias Mutex = NIOLockedValueBox

  @available(SwiftStdlib 5.5, *)
  extension NIOLockedValueBox {
    /// Add a wrap function to make it easier to migrate to Mutex in the future.
    public func withLock<Result>(_ body: (inout Value) throws -> Result) rethrows -> Result {
      try withLockedValue(body)
    }
  }
#else
  import Synchronization
#endif

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public struct Lockable {

  public enum AccessLevel {
    case `open`
    case `public`
    case `package`
    case `internal`
    case `fileprivate`
    case `private`
  }

  public enum Accessor {
    case get
    case set
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
@attached(memberAttribute)
public macro Lockable() = #externalMacro(module: "SynchronizationMacros", type: "LockableMacro")

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
@attached(accessor, names: named(get), named(set))
@attached(peer, names: prefixed(_))
public macro LockableTracked(
  accessLevel: Lockable.AccessLevel = .private,
  accessors: Lockable.Accessor...
) = #externalMacro(module: "SynchronizationMacros", type: "LockableTrackedMacro")

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
@attached(peer)
public macro LockableIgnored() =
  #externalMacro(module: "SynchronizationMacros", type: "LockableIgnoredMacro")
