// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

@available(SwiftStdlib 5.9, *)
extension Duration {

  /// Value of `Duration.seconds(Double.greatestFiniteMagnitude)`.
  public static var max: Duration {
    .seconds(Double.greatestFiniteMagnitude)
  }
}
