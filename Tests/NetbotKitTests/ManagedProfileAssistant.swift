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

import _ProfileSupport

@testable import NetbotKit

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(SwiftData)
  import SwiftData
#endif

@available(SwiftStdlib 5.9, *)
func withManagedProfile(body: (ProfileAssistant) async throws -> Void) async throws {
  #if canImport(SwiftData)
    let schema: Schema = Schema(versionedSchema: _VersionedSchema.self)
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let modelContainer = try ModelContainer(for: schema, configurations: configuration)
    let profileAssistant = ProfileAssistant(modelContainer: modelContainer)
  #else
    let profileAssistant = ProfileAssistant()
  #endif
  let profileURL = URL(filePath: #filePath).deletingLastPathComponent()
    .appending(path: UUID().uuidString).appendingPathExtension(.profilePathExtension)
  try "".write(to: profileURL, atomically: true, encoding: .utf8)
  await profileAssistant.setProfileURL(profileURL)
  await profileAssistant.setProfilesDirectory(profileURL.deletingLastPathComponent())
  try await body(profileAssistant)
  try FileManager.default.removeItem(at: profileURL)
}
