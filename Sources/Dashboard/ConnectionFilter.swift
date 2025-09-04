//
// See LICENSE.txt for license information
//

@available(SwiftStdlib 5.3, *)
public enum ConnectionFilter: Hashable {
  case client(String?)
  case hostname(String?)
}
