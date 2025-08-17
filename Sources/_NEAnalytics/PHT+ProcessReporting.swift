//
// See LICENSE.txt for license information
//

#if os(macOS)
  import Anlzr
  import AnlzrReports
  import NEAddressProcessing
  import _PrivilegeSupport

  extension PrivilegeScope: ProcessReporting {

    public func processInfo(address: Address) async throws -> ProcessReport {
      guard let port = address.port, port <= Int(UInt16.max), port >= 0 else {
        throw AnlzrError.operationUnsupported
      }
      let processInfo = try await processInfo(address: UInt16(port))
      return ProcessReport(
        processIdentifier: processInfo?.processIdentifier,
        program: Program(
          localizedName: processInfo?.processName ?? "Unknown",
          bundleURL: processInfo?.processBundleURL,
          executableURL: processInfo?.processExecutableURL,
          iconTIFFRepresentation: processInfo?.processIconTIFFRepresentation
        )
      )
    }
  }
#endif
