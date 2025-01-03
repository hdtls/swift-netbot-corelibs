//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  public import FoundationEssentials
#else
  public import Foundation
#endif

#if canImport(Combine)
  public import Combine
#else
  public import OpenCombine
#endif

public struct ProfileInfo: Equatable, Hashable, Identifiable, Sendable {

  public var id: URL { url }

  public var url: URL

  public var name: String {
    url.deletingPathExtension().lastPathComponent
  }

  public var numberOfRules: Int

  public var numberOfProxies: Int
}

@MainActor final public class ProfileResource: ObservableObject {

  @Published public var profiles: [ProfileInfo] = []

  nonisolated internal init() {

  }
}
