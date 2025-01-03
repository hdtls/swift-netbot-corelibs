//
// See LICENSE.txt for license information
//

#if canImport(Darwin)
  public import UniformTypeIdentifiers

  @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
  extension UTType {

    /// A type that represents Netbot configuration file data.
    ///
    /// **UTI:** com.tenbits.netbot-cfg
    /// **conforms to:** public.text
    public static var profile: UTType {
      UTType(exportedAs: "com.tenbits.netbot-cfg", conformingTo: .text)
    }
  }
#endif
