//
// See LICENSE.txt for license information
//

#if !canImport(UniformTypeIdentifiers)
  @_exported public import FoundationEssentials

  extension URL {

    public func appendingPathComponent(_ partialName: String, conformingTo contentType: UTType)
      -> URL
    {
      self
    }
  }
#endif
