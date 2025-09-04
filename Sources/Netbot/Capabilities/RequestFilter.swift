//
// See LICENSE.txt for license information
//

import Preference

@available(SwiftStdlib 5.3, *)
public enum RequestFilterStrategy: Int, CaseIterable, Hashable, Sendable {
  case noFilter
  case withKeywords
  case withoutKeywords
  case matchPatterns
}

@available(SwiftStdlib 5.3, *)
extension RequestFilterStrategy {

  public var abstract: String {
    switch self {
    case .noFilter:
      return "No Filter"
    case .withKeywords:
      return "Record Requests with Keywords Only"
    case .withoutKeywords:
      return "Record Requests without Keywords Only"
    case .matchPatterns:
      return "Record Requests Match Patterns"
    }
  }
}

@available(SwiftStdlib 5.3, *)
extension RequestFilterStrategy: PreferenceRepresentable {}

@available(SwiftStdlib 5.3, *)
public struct RequestFilter: Hashable, Sendable {

  public var strategy: RequestFilterStrategy

  public var values: [String]

  public init(strategy: RequestFilterStrategy = .noFilter, values: [String] = []) {
    self.strategy = strategy
    self.values = values
  }
}

@available(SwiftStdlib 5.3, *)
extension RequestFilter: PreferenceRepresentable {

  public init?(preferenceValue: Any) {
    guard let prefs = preferenceValue as? [String: Any] else {
      return nil
    }

    guard let rawValue = prefs["strategy"] as? Int,
      let strategy = RequestFilterStrategy(rawValue: rawValue)
    else {
      return nil
    }
    self.strategy = strategy
    self.values = prefs["values"] as? [String] ?? []
  }

  public var preferenceValue: Any? {
    ["strategy": strategy.preferenceValue, "values": values]
  }
}
