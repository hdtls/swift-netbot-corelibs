//
// See LICENSE.txt for license information
//

public import HTTPTypes

extension AnyProxy {

  /// WebSocket settings for VMESS protocol.
  public struct WebSocket: Codable, Hashable, Sendable {

    /// A boolean value determine whether WebSocket should be enabled.
    public var isEnabled: Bool = false

    /// The URL path of WebSocket request.
    public var uri: String = "/"

    /// Addition HTTP fields of WebSocket request.
    public var additionalHTTPFields: HTTPFields?

    /// Initialize an instance of `WebSocket` settings with specified parameters.
    public init(isEnabled: Bool = false, uri: String = "/", additionalHTTPFields: HTTPFields? = nil)
    {
      self.isEnabled = isEnabled
      self.uri = uri
      self.additionalHTTPFields = additionalHTTPFields
    }
  }
}
