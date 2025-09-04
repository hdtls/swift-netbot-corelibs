//
// See LICENSE.txt for license information
//

@available(SwiftStdlib 5.3, *)
extension AnyProxy {

  /// `Source`` indicates if the proxy was builtin, user defined or resolved from external resource.
  public enum Source: String, CaseIterable, Codable, Hashable, Sendable {

    /// Built-in.
    case builtin

    /// User defined.
    case userDefined

    /// Resolved from external resource..
    case externalResource
  }
}
