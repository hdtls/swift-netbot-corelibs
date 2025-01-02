//
// See LICENSE.txt for license information
//

@testable import NetbotData

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(SwiftData)
  import SwiftData
#endif

@available(swift 5.9)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
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
