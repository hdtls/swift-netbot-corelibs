//
// See LICENSE.txt for license information
//

#if canImport(Darwin)
  import Foundation
#endif

@available(SwiftStdlib 5.3, *)
extension AnyProxyGroup {
  public enum Kind: String, CaseIterable, Codable, Hashable, Sendable {
    case select
    case urlTest = "url-test"
    case fallback
    case ssid
    case loadBalance = "load-balance"

    @available(SwiftStdlib 5.5, *)
    public var localizedName: String {
      switch self {
      #if canImport(Darwin)
        case .select: return String(localized: "Select Group")
        case .urlTest: return String(localized: "Auto URL Test Group")
        case .fallback: return String(localized: "Fallback Group")
        case .ssid: return String(localized: "SSID Group")
        case .loadBalance: return String(localized: "Load Balance Group")
      #else
        case .select: return "Select Group"
        case .urlTest: return "Auto URL Test Group"
        case .fallback: return "Fallback Group"
        case .ssid: return "SSID Group"
        case .loadBalance: return "Load Balance Group"
      #endif
      }
    }

    @available(SwiftStdlib 5.5, *)
    public var localizedDescription: String {
      switch self {
      #if canImport(Darwin)
        case .select:
          return String(localized: "Select which policy will be used on user interface.")
        case .urlTest:
          return String(
            localized:
              "Automatically select which policy will be used by benchmarking the latency to a URL."
          )
        case .fallback:
          return String(
            localized:
              "Automatically select an available policy by priority. The availability is tested by accessing a URL like the auto URL test group."
          )
        case .ssid:
          return String(
            localized: "Select which policy will be used according to the current Wi-Fi SSID.")
        case .loadBalance:
          return String(localized: "Use a random sub-policy for every connections.")
      #else
        case .select:
          return "Select which policy will be used on user interface."
        case .urlTest:
          return
            "Automatically select which policy will be used by benchmarking the latency to a URL."
        case .fallback:
          return
            "Automatically select an available policy by priority. The availability is tested by accessing a URL like the auto URL test group."
        case .ssid:
          return "Select which policy will be used according to the current Wi-Fi SSID."
        case .loadBalance:
          return "Use a random sub-policy for every connections."
      #endif
      }
    }
  }
}
