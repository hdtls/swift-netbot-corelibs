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

// There is a bug for swift-foramt, until that bug fixed, we ignore the file.
// swift-format-ignore-file

#if swift(<6.2)
  @available(SwiftStdlib 6.0, *)
  extension Result where Success: ~Copyable {
    /// Creates a new result by evaluating an async throwing closure, capturing the
    /// returned value as a success, or any thrown error as a failure.
    ///
    /// - Parameter body: A potentially throwing async closure to evaluate.
    nonisolated public init(catching body: () async throws(Failure) -> Success) async {
      do {
        self = .success(try await body())
      } catch {
        self = .failure(error)
      }
    }
  }
#elseif swift(<6.4)
  @available(SwiftStdlib 6.0, *)
  extension Result where Success: ~Copyable {
    /// Creates a new result by evaluating an async throwing closure, capturing the
    /// returned value as a success, or any thrown error as a failure.
    ///
    /// - Parameter body: A potentially throwing async closure to evaluate.
    nonisolated(nonsending) public init(
      catching body: nonisolated(nonsending) () async throws(Failure) -> Success
    ) async {
      do {
        self = .success(try await body())
      } catch {
        self = .failure(error)
      }
    }
  }
#endif
