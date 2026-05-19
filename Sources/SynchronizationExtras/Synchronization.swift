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

#if canImport(Darwin) && NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @_exported public import Atomics
  @_exported public import NIOConcurrencyHelpers

  @available(SwiftStdlib 5.9, *)
  public typealias Atomic = ManagedAtomic

  @available(SwiftStdlib 5.9, *)
  public typealias Mutex = NIOLockedValueBox

  @available(SwiftStdlib 5.9, *)
  extension Atomic where Value == Int {

    @_semantics("atomics.requires_constant_orderings")
    @_transparent @_alwaysEmitIntoClient
    @discardableResult
    public func wrappingAdd(_ operand: Int, ordering: AtomicUpdateOrdering) -> (
      oldValue: Int,
      newValue: Int
    ) {
      (
        loadThenWrappingIncrement(by: operand, ordering: ordering),
        load(ordering: .relaxed)
      )
    }
  }

  @available(SwiftStdlib 5.9, *)
  extension Atomic where Value == UInt32 {

    @_semantics("atomics.requires_constant_orderings")
    @_transparent @_alwaysEmitIntoClient
    @discardableResult
    public func wrappingAdd(_ operand: UInt32, ordering: AtomicUpdateOrdering) -> (
      oldValue: UInt32,
      newValue: UInt32
    ) {
      (
        loadThenWrappingIncrement(by: operand, ordering: ordering),
        load(ordering: .relaxed)
      )
    }
  }

  @available(SwiftStdlib 5.9, *)
  extension Atomic where Value == UInt64 {

    @_semantics("atomics.requires_constant_orderings")
    @_transparent @_alwaysEmitIntoClient
    @discardableResult
    public func wrappingAdd(_ operand: UInt64, ordering: AtomicUpdateOrdering) -> (
      oldValue: UInt64,
      newValue: UInt64
    ) {
      (
        loadThenWrappingIncrement(by: operand, ordering: ordering),
        load(ordering: .relaxed)
      )
    }
  }

  @available(SwiftStdlib 5.9, *)
  extension Mutex {
    /// Add a wrap function to make it easier to migrate to Mutex in the future.
    public func withLock<Result>(_ body: (inout Value) throws -> Result) rethrows -> Result {
      try withLockedValue(body)
    }
  }
#else
  @_exported public import Synchronization
#endif

#if compiler(>=6.2)
  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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

#if compiler(>=6.2)
  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
#endif
@attached(memberAttribute)
public macro Lockable() = #externalMacro(module: "SynchronizationMacros", type: "LockableMacro")

#if compiler(>=6.2)
  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
#endif
@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: prefixed(`$`))
public macro LockableTracked(
  accessLevel: Lockable.AccessLevel = .private,
  accessors: Lockable.Accessor...
) = #externalMacro(module: "SynchronizationMacros", type: "LockableTrackedMacro")

#if compiler(>=6.2)
  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
#endif
@attached(peer)
public macro LockableIgnored() =
  #externalMacro(module: "SynchronizationMacros", type: "LockableIgnoredMacro")
