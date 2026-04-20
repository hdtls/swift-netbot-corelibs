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

import NIOConcurrencyHelpers

public typealias Mutex = NIOLockedValueBox

extension NIOLockedValueBox {

  /// Add a wrap function to make it easier to migrate to Mutex in the future.
  public func withLock<Result>(_ body: (inout Value) throws -> Result) rethrows -> Result {
    try withLockedValue(body)
  }
}

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

@attached(memberAttribute)
public macro Lockable() = #externalMacro(module: "SynchronizationMacros", type: "LockableMacro")

@attached(accessor, names: named(get), named(set))
@attached(peer, names: prefixed(_))
public macro LockableTracked(
  accessLevel: Lockable.AccessLevel = .private,
  accessors: Lockable.Accessor...
) = #externalMacro(module: "SynchronizationMacros", type: "LockableTrackedMacro")

@attached(peer)
public macro LockableIgnored() =
  #externalMacro(module: "SynchronizationMacros", type: "LockableIgnoredMacro")
