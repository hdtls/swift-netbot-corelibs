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

// swift-format-ignore-file

@_spi(SwiftUI)
@attached(member, names: named(profileURL), named(dismiss), named(modelContext), named(profileAssistant), named(data), named(persistentModel), named(init), named(save))
public macro Editable<Data>(data: Data.Type = Data.self) = #externalMacro(module: "NetbotFrontendMacros", type: "EditableMacro")
