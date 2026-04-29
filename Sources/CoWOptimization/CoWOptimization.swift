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

/// Defines and implements copy on write.
///
/// This macro adds copy on write support to a custom type. For example, the following code
/// applies the `_cowOptimization` macro to the type `Car` making it copy on write:
///
///     @_cowOptimization
///     struct Car {
///        var name: String = ""
///        var needsRepairs: Bool = false
///     }
#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
@attached(member, names: named(_storage), named(_Storage))
@attached(memberAttribute)
public macro _cowOptimization() =
  #externalMacro(module: "CoWOptimizationMacros", type: "CoWOptimizationMacro")

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
@attached(accessor, names: named(get), named(_modify))
public macro _cowOptimizationTracked() =
  #externalMacro(module: "CoWOptimizationMacros", type: "CoWOptimizationTrackedMacro")

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
@attached(peer)
public macro _cowOptimizationIgnored() =
  #externalMacro(module: "CoWOptimizationMacros", type: "CoWOptimizationIgnoredMacro")
