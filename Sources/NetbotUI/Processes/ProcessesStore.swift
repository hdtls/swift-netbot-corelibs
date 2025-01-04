//
// See LICENSE.txt for license information
//

#if os(macOS) && EXTENDED_ALL
  import Combine
  import Foundation
  public import Observation

  @Observable final public class ProcessesStore {
    public var processes: [ProcessStatistics] = []

    public init() {
    }
  }
#endif
