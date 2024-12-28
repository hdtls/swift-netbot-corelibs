//
// See LICENSE.txt for license information
//

public import _UniformTypeIdentifiers

#if canImport(Darwin)
  public import CoreTransferable
#endif

extension Profile {
  @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
  public static let contentType = UTType.profile
}

#if canImport(Darwin)
  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  extension Profile: Transferable {

    public static var transferRepresentation: some TransferRepresentation {
      FileRepresentation(contentType: .profile) { transferable in
        SentTransferredFile(transferable.url)
      } importing: { receivedTransferredFile in
        try Profile.FormatStyle().parse(String(contentsOf: receivedTransferredFile.file))
      }
      DataRepresentation(contentType: .profile) { item in
        await Task.detached {
          guard let data = item.formatted().data(using: .utf8) else {
            return Data()
          }
          return data
        }.value
      } importing: { data in
        try await Task.detached {
          let parseInput = String(data: data, encoding: .utf8) ?? ""
          return try Profile(parseInput, strategy: .profile)
        }.value
      }
    }
  }
#endif
