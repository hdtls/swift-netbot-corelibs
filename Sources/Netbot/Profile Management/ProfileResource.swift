//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(Combine)
  import Combine
#else
  import OpenCombine
#endif

@available(SwiftStdlib 5.3, *)
public struct ProfileInfo: Equatable, Hashable, Identifiable, Sendable {

  public var id: URL { url }

  public var url: URL

  public var name: String {
    url.deletingPathExtension().lastPathComponent
  }

  public var numberOfRules: Int

  public var numberOfProxies: Int
}

@available(SwiftStdlib 5.3, *)
@MainActor final public class ProfileResource: ObservableObject {

  @Published public var profiles: [ProfileInfo] = []

  nonisolated internal init() {

  }
}
