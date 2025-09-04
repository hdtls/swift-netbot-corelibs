//
// See LICENSE.txt for license information
//

/// A protocol that covers an object that does DNS lookups.
@available(SwiftStdlib 5.3, *)
public protocol Resolver {

  /// Lookup A records associated with `name`.
  ///
  /// - Parameters:
  ///   - name: The name to resolve.
  ///
  /// - Returns: ``ARecord``s for the given name, empty if no records were found.
  func queryA(name: String) async throws -> [ARecord]

  /// Lookup AAAA records associated with `name`.
  ///
  /// - Parameters:
  ///   - name: The name to resolve.
  ///
  /// - Returns: ``AAAARecord``s for the given name, empty if no records were found.
  func queryAAAA(name: String) async throws -> [AAAARecord]

  /// Lookup NS record associated with `name`.
  ///
  /// - Parameters:
  ///   - name: The name to resolve.
  ///
  /// - Returns: ``NSRecord`` for the given name.
  func queryNS(name: String) async throws -> [NSRecord]

  /// Lookup CNAME record associated with `name`.
  ///
  /// - Parameters:
  ///   - name: The name to resolve.
  ///
  /// - Returns: CNAME for the given name, `nil` if no record was found.
  func queryCNAME(name: String) async throws -> [CNAMERecord]

  /// Lookup SOA record associated with `name`.
  ///
  /// - Parameters:
  ///   - name: The name to resolve.
  ///
  /// - Returns: ``SOARecord`` for the given name, `nil` if no record was found.
  func querySOA(name: String) async throws -> [SOARecord]

  /// Lookup PTR record associated with `name`.
  ///
  /// - Parameters:
  ///   - name: The name to resolve.
  ///
  /// - Returns: ``PTRRecord`` for the given name.
  func queryPTR(name: String) async throws -> [PTRRecord]

  /// Lookup MX records associated with `name`.
  ///
  /// - Parameters:
  ///   - name: The name to resolve.
  ///
  /// - Returns: ``MXRecord``s for the given name, empty if no records were found.
  func queryMX(name: String) async throws -> [MXRecord]

  /// Lookup TXT records associated with `name`.
  ///
  /// - Parameters:
  ///   - name: The name to resolve.
  ///
  /// - Returns: ``TXTRecord``s for the given name, empty if no records were found.
  func queryTXT(name: String) async throws -> [TXTRecord]

  /// Lookup SRV records associated with `name`.
  ///
  /// - Parameters:
  ///   - name: The name to resolve.
  ///
  /// - Returns: ``SRVRecord``s for the given name, empty if no records were found.
  func querySRV(name: String) async throws -> [SRVRecord]
}
