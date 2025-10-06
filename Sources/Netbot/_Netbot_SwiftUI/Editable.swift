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

// swift-format-ignore-file

@attached(member, names: named(profileURL), named(dismiss), named(modelContext), named(profileAssistant), named(data), named(persistentModel), named(init), named(save))
public macro Editable<Data>(data: Data.Type = Data.self) = #externalMacro(module: "EditableMacros", type: "EditableMacro")
