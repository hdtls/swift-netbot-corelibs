//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

#if canImport(SwiftUI)
  import Alamofire
  import SwiftUI

  @available(SwiftStdlib 5.3, *)
  @_spi(SwiftUI) extension EnvironmentValues {

    @Entry public var urlSession = Session.default

    @Entry public var vpnSession = VPNSession.shared

    @available(SwiftStdlib 5.9, *)
    @Entry public var diagnostics = Diagnostics()

    @available(SwiftStdlib 5.9, *)
    @Entry public var profileAssistant = ProfileAssistant.shared
  }
#endif
