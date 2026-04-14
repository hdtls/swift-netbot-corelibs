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

import Testing

extension Tag {
  @Tag static var profile: Tag

  @Tag static var proxy: Tag

  @Tag static var proxyGroup: Tag

  @Tag static var forwardingRule: Tag

  @Tag static var dns: Tag

  @Tag static var dnsMapping: Tag

  @Tag static var urlRewrite: Tag

  @Tag static var stubbedHTTPResponse: Tag

  @Tag static var httpFieldsRewrite: Tag

  @Tag static var swiftData: Tag

  @Tag static var schema: Tag

  @Tag static var formatting: Tag
}
