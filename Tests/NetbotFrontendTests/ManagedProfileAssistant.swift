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

import NetbotProfile

@testable import NetbotFrontend

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(SwiftData)
  import SwiftData
#endif

// swift-format-ignore: AlwaysUseLowerCamelCase
let __dir = UUID()

@available(SwiftStdlib 6.0, *)
func withManagedProfile(body: (ProfileAssistant) async throws -> Void) async throws {
  #if canImport(SwiftData)
    let schema: Schema = Schema(versionedSchema: _VersionedSchema.self)
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let modelContainer = try ModelContainer(for: schema, configurations: configuration)
    let profileAssistant = ProfileAssistant(modelContainer: modelContainer)
  #else
    let profileAssistant = ProfileAssistant()
  #endif
  let profilesDirectory = URL.temporaryDirectory
    .appending(path: __dir.uuidString, directoryHint: .isDirectory)
  try FileManager.default.createDirectory(at: profilesDirectory, withIntermediateDirectories: true)
  let profileURL = profilesDirectory.appending(path: UUID().uuidString)
    .appendingPathExtension(.profilePathExtension)
  try "".write(to: profileURL, atomically: true, encoding: .utf8)
  await profileAssistant.setProfileURL(profileURL)
  await profileAssistant.setProfilesDirectory(profilesDirectory)
  try await body(profileAssistant)
  try FileManager.default.removeItem(at: profileURL)
}
