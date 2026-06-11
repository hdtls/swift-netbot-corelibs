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

#if compiler(>=6.2)
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

#if compiler(>=6.2)
  @available(SwiftStdlib 6.0, *)
#endif
@attached(memberAttribute)
public macro Lockable() = #externalMacro(module: "SynchronizationMacros", type: "LockableMacro")

#if compiler(>=6.2)
  @available(SwiftStdlib 6.0, *)
#endif
@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: prefixed(`$`))
public macro LockableTracked(
  accessLevel: Lockable.AccessLevel = .private,
  accessors: Lockable.Accessor...
) = #externalMacro(module: "SynchronizationMacros", type: "LockableTrackedMacro")

#if compiler(>=6.2)
  @available(SwiftStdlib 6.0, *)
#endif
@attached(peer)
public macro LockableIgnored() =
  #externalMacro(module: "SynchronizationMacros", type: "LockableIgnoredMacro")

#if canImport(Darwin) || swift(>=6.3)
  import Observation

  #if compiler(>=6.2)
    @available(SwiftStdlib 6.0, *)
  #endif
  @attached(
    member, names: named(_$observationRegistrar), named(access), named(withMutation),
    named(shouldNotifyObservers)) @attached(memberAttribute)
  @attached(
    extension, conformances: Observable)
  public macro ObservationLockable() =
    #externalMacro(module: "SynchronizationMacros", type: "ObservationLockableMacro")
#else
  #if compiler(>=6.2)
    @available(SwiftStdlib 6.0, *)
  #endif
  @attached(member, names: named(access), named(withMutation))
  @attached(memberAttribute)
  public macro ObservationLockable() =
    #externalMacro(module: "SynchronizationMacros", type: "ObservationLockableMacro")
#endif

#if compiler(>=6.2)
  @available(SwiftStdlib 6.0, *)
#endif
@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: prefixed(`$`))
public macro ObservationLockableTracked(
  accessLevel: Lockable.AccessLevel = .private
) = #externalMacro(module: "SynchronizationMacros", type: "ObservationLockableTrackedMacro")

#if compiler(>=6.2)
  @available(SwiftStdlib 6.0, *)
#endif
@attached(peer)
public macro ObservationLockableIgnored() =
  #externalMacro(module: "SynchronizationMacros", type: "ObservationLockableIgnoredMacro")
