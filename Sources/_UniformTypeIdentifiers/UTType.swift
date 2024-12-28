//
// See LICENSE.txt for license information
//

#if canImport(UniformTypeIdentifiers)
  @_exported public import UniformTypeIdentifiers
#else
  public struct UTType: Sendable {

    public var identifier: String {
      _identifier
    }
    private var _identifier: String

    public var preferredFilenameExtension: String? { nil }

    public init(exportedAs identifier: String, conformingTo parentType: UTType? = nil) {
      self._identifier = identifier
    }

    public init?(_ identifier: String) {
      self._identifier = identifier
    }
  }
#endif

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension UTType {

  /**
    The base type for all text-encoded data, including text with markup
    (HTML, RTF, etc.).

    **UTI:** public.text

    **conforms to:** public.data, public.content
  */

  /// A type that represents Netbot configuration file data.
  ///
  /// **UTI:** com.tenbits.netbot-cfg
  /// **conforms to:** public.text
  public static var profile: UTType {
    UTType(exportedAs: "com.tenbits.netbot-cfg", conformingTo: .text)
  }

  public static var text: UTType {
    UTType("public.text")!
  }
}
