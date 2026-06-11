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

#if canImport(SwiftUI)
  import Alamofire
  import SwiftUI

  @available(SwiftStdlib 6.0, *)
  @_spi(SwiftUI) extension EnvironmentValues {

    @Entry public var urlSession = Alamofire.Session.default

    @Entry public var session = Session.shared

    @Entry public var diagnostics = Diagnostics()

    @Entry public var profileAssistant = ProfileAssistant.default
  }
#endif
