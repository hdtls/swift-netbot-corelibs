//
// See LICENSE.txt for license information
//

@_exported import HTTPTypes

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

/// A stubbed HTTP response representation object, define how to stub response for request.
@available(SwiftStdlib 5.3, *)
public struct StubbedHTTPResponse: Equatable, Hashable, Sendable {

  /// A boolean value determinse whether this rule is enabled or disabled.
  public var isEnabled = true

  /// Incoming request URL matching pattern.
  public var pattern: String = ""

  /// Response body content URL.
  public var bodyContentsURL: URL?

  /// Response status.
  public var status: HTTPResponse.Status = .ok

  /// Additional HTTP fields for stubbed response.
  public var additionalHTTPFields: HTTPFields = HTTPFields()

  /// The time the resource was created.
  public var creationDate: Date

  /// Create a `StubbedHTTPResponse` with specified values.
  public init(
    isEnabled: Bool = true,
    pattern: String = "",
    bodyContentsURL: URL? = nil,
    status: HTTPResponse.Status = .ok,
    additionalHTTPFields: HTTPFields = HTTPFields()
  ) {
    self.isEnabled = isEnabled
    self.pattern = pattern
    self.bodyContentsURL = bodyContentsURL
    self.status = status
    self.additionalHTTPFields = additionalHTTPFields
    if #available(SwiftStdlib 5.5, *) {
      self.creationDate = .now
    } else {
      self.creationDate = .init()
    }
  }
}
