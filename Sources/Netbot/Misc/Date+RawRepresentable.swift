//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 5.3, *)
extension Date: @retroactive RawRepresentable {

  public var rawValue: String {
    self.timeIntervalSinceReferenceDate.description
  }

  public init?(rawValue: RawValue) {
    guard let timeInterval = TimeInterval(rawValue) else {
      return nil
    }
    self = Date(timeIntervalSinceReferenceDate: timeInterval)
  }
}
