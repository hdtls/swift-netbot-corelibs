//
// See LICENSE.txt for license information
//

public import NEAddressProcessing
public import NIOCore

public enum DNSParserError: Error {
  case invalidPayloadData
  case notImplemented
}

public struct DNSParser: Sendable {

  public init() {}

  public func parse(_ parseInput: ByteBuffer) throws -> Message {
    var parseInput = parseInput

    let headerFields = try parseHeaderFieldsIfAvailable(&parseInput)

    var questions: [Question] = []
    var numberOfLoops = headerFields.qestionCount
    while numberOfLoops > 0 {
      let question = try parseQuestionIfAvailable(&parseInput)
      questions.append(question)
      numberOfLoops -= 1
    }

    var answers: [any RecordProtocol] = []
    numberOfLoops = headerFields.answerCount
    while numberOfLoops > 0 {
      let answer = try parseRRIfAvailable(&parseInput)
      answers.append(answer)
      numberOfLoops -= 1
    }

    var authorities: [any RecordProtocol] = []
    numberOfLoops = headerFields.authorityCount
    while numberOfLoops > 0 {
      let authority = try parseRRIfAvailable(&parseInput)
      authorities.append(authority)
      numberOfLoops -= 1
    }

    var additionals: [any RecordProtocol] = []
    numberOfLoops = headerFields.additionCount
    while numberOfLoops > 0 {
      let additional = try parseRRIfAvailable(&parseInput)
      additionals.append(additional)
      numberOfLoops -= 1
    }

    let message = Message(
      headerFields: headerFields,
      questions: questions,
      answerRRs: answers,
      authorityRRs: authorities,
      additionalRRs: additionals
    )

    return message
  }

  private func parseHeaderFieldsIfAvailable(_ parseInput: inout ByteBuffer) throws
    -> Message.HeaderFields
  {
    /// The header contains the following fields:
    ///
    ///     0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15
    ///    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///    |                      ID                       |
    ///    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///    |QR|   Opcode  |AA|TC|RD|RA|Z |     RCODE       |
    ///    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///    |                    QDCOUNT                    |
    ///    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///    |                    ANCOUNT                    |
    ///    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///    |                    NSCOUNT                    |
    ///    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///    |                    ARCOUNT                    |
    ///    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///
    /// where:
    ///
    /// ID              A 16 bit identifier assigned by the program that
    ///                generates any kind of query.  This identifier is copied
    ///                the corresponding reply and can be used by the requester
    ///                to match up replies to outstanding queries.
    ///
    /// QR              A one bit field that specifies whether this message is a
    ///                query (0), or a response (1).
    ///
    /// OPCODE          A four bit field that specifies kind of query in this
    ///                message.  This value is set by the originator of a query
    ///                and copied into the response.  The values are:
    ///
    ///                0               a standard query (QUERY)
    ///
    ///                1               an inverse query (IQUERY)
    ///
    ///                2               a server status request (STATUS)
    ///
    ///                3-15            reserved for future use
    ///
    /// AA              Authoritative Answer - this bit is valid in responses,
    ///                and specifies that the responding name server is an
    ///                authority for the domain name in question section.
    ///
    ///                Note that the contents of the answer section may have
    ///                multiple owner names because of aliases.  The AA bit
    ///
    ///                corresponds to the name which matches the query name, or
    ///                the first owner name in the answer section.
    ///
    /// TC              TrunCation - specifies that this message was truncated
    ///                due to length greater than that permitted on the
    ///                transmission channel.
    ///
    /// RD              Recursion Desired - this bit may be set in a query and
    ///                is copied into the response.  If RD is set, it directs
    ///                the name server to pursue the query recursively.
    ///                Recursive query support is optional.
    ///
    /// RA              Recursion Available - this be is set or cleared in a
    ///                response, and denotes whether recursive query support is
    ///                available in the name server.
    ///
    /// Z               Reserved for future use.  Must be zero in all queries
    ///                and responses.
    ///
    /// RCODE           Response code - this 4 bit field is set as part of
    ///                responses.  The values have the following
    ///                interpretation:
    ///
    ///                0               No error condition
    ///
    ///                1               Format error - The name server was
    ///                                unable to interpret the query.
    ///
    ///                2               Server failure - The name server was
    ///                                unable to process this query due to a
    ///                                problem with the name server.
    ///
    ///                3               Name Error - Meaningful only for
    ///                                responses from an authoritative name
    ///                                server, this code signifies that the
    ///                                domain name referenced in the query does
    ///                                not exist.
    ///
    ///                4               Not Implemented - The name server does
    ///                                not support the requested kind of query.
    ///
    ///                5               Refused - The name server refuses to
    ///                                perform the specified operation for
    ///                                policy reasons.  For example, a name
    ///                                server may not wish to provide the
    ///                                information to the particular requester,
    ///                                or a name server may not wish to perform
    ///                                a particular operation (e.g., zone transfer) for
    ///                                particular data.
    ///
    ///                6-15            Reserved for future use.
    ///
    /// QDCOUNT         an unsigned 16 bit integer specifying the number of
    ///                entries in the question section.
    ///
    /// ANCOUNT         an unsigned 16 bit integer specifying the number of
    ///                resource records in the answer section.
    ///
    /// NSCOUNT         an unsigned 16 bit integer specifying the number of name
    ///                server resource records in the authority records
    ///                section.
    ///
    /// ARCOUNT         an unsigned 16 bit integer specifying the number of
    ///                resource records in the additional records section.

    guard let id = parseInput.readInteger(as: UInt16.self) else {
      throw DNSParserError.invalidPayloadData
    }

    guard let flags = parseInput.readInteger(as: UInt16.self) else {
      throw DNSParserError.invalidPayloadData
    }

    guard var qdCount = parseInput.readInteger(as: UInt16.self) else {
      throw DNSParserError.invalidPayloadData
    }

    guard var anCount = parseInput.readInteger(as: UInt16.self) else {
      throw DNSParserError.invalidPayloadData
    }

    guard var nsCount = parseInput.readInteger(as: UInt16.self) else {
      throw DNSParserError.invalidPayloadData
    }

    guard var arCount = parseInput.readInteger(as: UInt16.self) else {
      throw DNSParserError.invalidPayloadData
    }

    let headerFields = Message.HeaderFields(
      transactionID: id,
      flags: .init(rawValue: flags),
      qestionCount: qdCount,
      answerCount: anCount,
      authorityCount: nsCount,
      additionCount: arCount
    )

    return headerFields
  }

  private func parseLengthPrefixedString(_ parseInput: inout ByteBuffer) throws -> String {
    guard let l = parseInput.readInteger(as: UInt8.self) else {
      throw DNSParserError.invalidPayloadData
    }
    guard let parseOutput = parseInput.readString(length: Int(l)) else {
      throw DNSParserError.invalidPayloadData
    }
    return parseOutput
  }

  private func parseLabelIfAvailable(_ parseInput: inout ByteBuffer) throws -> String {
    var label = try parseLengthPrefixedString(&parseInput)

    while true {
      guard let l = parseInput.getInteger(at: parseInput.readerIndex, as: UInt8.self) else {
        throw DNSParserError.invalidPayloadData
      }

      // Name end with 0 length label.
      guard l > 0 else {
        // Skip terminator byte.
        parseInput.moveReaderIndex(forwardBy: MemoryLayout<UInt8>.size)
        break
      }

      if !label.isEmpty {
        label += "."
      }
      label += try parseLengthPrefixedString(&parseInput)
    }
    return label
  }

  private func parseQuestionIfAvailable(_ parseInput: inout ByteBuffer) throws -> Question {
    /// The question section is used to carry the "question" in most queries,
    /// i.e., the parameters that define what is being asked.  The section
    /// contains QDCOUNT (usually 1) entries, each of the following format:
    ///
    ///      0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     |                                               |
    ///     /                     QNAME                     /
    ///     /                                               /
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     |                     QTYPE                     |
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     |                     QCLASS                    |
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///
    /// where:
    ///
    /// QNAME           a domain name represented as a sequence of labels, where
    ///                 each label consists of a length octet followed by that
    ///                 number of octets.  The domain name terminates with the
    ///                 zero length octet for the null label of the root.  Note
    ///                 that this field may be an odd number of octets; no
    ///                 padding is used.
    ///
    /// QTYPE           a two octet code which specifies the type of the query.
    ///                 The values for this field include all codes valid for a
    ///                 TYPE field, together with some more general codes which
    ///                 can match more than one type of RR.
    ///
    /// QCLASS          a two octet code that specifies the class of the query.
    ///                 For example, the QCLASS field is IN for the Internet.

    let domainName = try parseLabelIfAvailable(&parseInput)

    guard let qType = parseInput.readInteger(as: UInt16.self) else {
      throw DNSParserError.invalidPayloadData
    }

    guard let qClass = parseInput.readInteger(as: UInt16.self) else {
      throw DNSParserError.invalidPayloadData
    }

    let question = Question(
      domainName: domainName,
      queryType: .init(rawValue: qType),
      queryClass: QueryClass(rawValue: qClass) ?? .internet
    )

    return question
  }

  private func parseRRIfAvailable(_ parseInput: inout ByteBuffer) throws -> any RecordProtocol {
    /// The answer, authority, and additional sections all share the same
    /// format: a variable number of resource records, where the number of
    /// records is specified in the corresponding count field in the header.
    /// Each resource record has the following format:
    ///
    ///      0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     |                                               |
    ///     /                                               /
    ///     /                      NAME                     /
    ///     |                                               |
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     |                      TYPE                     |
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     |                     CLASS                     |
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     |                      TTL                      |
    ///     |                                               |
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///     |                   RDLENGTH                    |
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--|
    ///     /                     RDATA                     /
    ///     /                                               /
    ///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    ///
    /// where:
    ///
    /// NAME            a domain name to which this resource record pertains.
    ///
    /// TYPE            two octets containing one of the RR type codes.  This
    ///                 field specifies the meaning of the data in the RDATA
    ///                 field.
    ///
    /// CLASS           two octets which specify the class of the data in the
    ///                 RDATA field.
    ///
    /// TTL             a 32 bit unsigned integer that specifies the time
    ///                 interval (in seconds) that the resource record may be
    ///                 cached before it should be discarded.  Zero values are
    ///                 interpreted to mean that the RR can only be used for the
    ///                 transaction in progress, and should not be cached.
    ///
    ///
    /// RDLENGTH        an unsigned 16 bit integer that specifies the length in
    ///                 octets of the RDATA field.
    ///
    /// RDATA           a variable length string of octets that describes the
    ///                 resource.  The format of this information varies
    ///                 according to the TYPE and CLASS of the resource record.
    ///                 For example, the if the TYPE is A and the CLASS is IN,
    ///                 the RDATA field is a 4 octet ARPA Internet address.

    let name = try parseLabelIfAvailable(&parseInput)

    guard let rrtype = parseInput.readInteger(as: UInt16.self) else {
      throw DNSParserError.invalidPayloadData
    }
    let recordType = QueryType(rawValue: rrtype)

    guard let rrclass = parseInput.readInteger(as: UInt16.self) else {
      throw DNSParserError.invalidPayloadData
    }
    let recordClass = QueryClass(rawValue: rrclass)

    guard let ttl = parseInput.readInteger(as: Int32.self) else {
      throw DNSParserError.invalidPayloadData
    }

    guard let dataLength = parseInput.readInteger(as: UInt16.self) else {
      throw DNSParserError.invalidPayloadData
    }

    guard var _parseInput = parseInput.readSlice(length: Int(dataLength)) else {
      throw DNSParserError.invalidPayloadData
    }

    let finalize: any RecordProtocol

    switch recordType {
    case .a:
      guard let data = IPv4Address(.init(buffer: _parseInput)) else {
        throw DNSParserError.invalidPayloadData
      }
      finalize = ARecord(
        ownerName: name,
        recordType: recordType,
        recordClass: recordClass,
        ttl: ttl,
        data: data
      )
    case .ns:
      finalize = NSRecord(
        ownerName: name,
        recordType: recordType,
        recordClass: recordClass,
        ttl: ttl,
        data: try parseLabelIfAvailable(&_parseInput)
      )
    case .cname:
      finalize = CNAMERecord(
        ownerName: name,
        recordType: recordType,
        recordClass: recordClass,
        ttl: ttl,
        data: try parseLabelIfAvailable(&_parseInput)
      )
    case .soa:
      finalize = SOARecord(
        ownerName: name,
        recordType: recordType,
        recordClass: recordClass,
        ttl: ttl,
        data: try parseSOARDataIfAvailable(&_parseInput)
      )
    case .ptr:
      finalize = PTRRecord(
        ownerName: name,
        recordType: recordType,
        recordClass: recordClass,
        ttl: ttl,
        data: try parseLabelIfAvailable(&_parseInput)
      )
    case .mx:
      finalize = MXRecord(
        ownerName: name,
        recordType: recordType,
        recordClass: recordClass,
        ttl: ttl,
        data: try parseMXRDataIfAvailable(&_parseInput)
      )
    case .txt:
      finalize = TXTRecord(
        ownerName: name,
        recordType: recordType,
        recordClass: recordClass,
        ttl: ttl,
        data: try parseLengthPrefixedString(&_parseInput)
      )
    case .aaaa:
      guard let data = IPv6Address(.init(buffer: _parseInput)) else {
        throw DNSParserError.invalidPayloadData
      }
      finalize = AAAARecord(
        ownerName: name,
        recordType: recordType,
        recordClass: recordClass,
        ttl: ttl,
        data: data
      )
    case .srv:
      finalize = SRVRecord(
        ownerName: name,
        recordType: recordType,
        recordClass: recordClass,
        ttl: ttl,
        data: try parseSRVRDataIfAvailable(&_parseInput)
      )
    case .naptr:
      finalize = NAPTRRecord(
        ownerName: name,
        recordType: recordType,
        recordClass: recordClass,
        ttl: ttl,
        data: try parseNAPTRRDataIfAvailable(&_parseInput)
      )
    default:
      throw DNSParserError.notImplemented
    }

    return finalize
  }

  private func parseSOARDataIfAvailable(_ parseInput: inout ByteBuffer) throws -> SOARecord.Data {
    SOARecord.Data(
      primaryNameServer: try parseLabelIfAvailable(&parseInput),
      responsibleMailbox: try parseLabelIfAvailable(&parseInput),
      serialNumber: parseInput.readInteger() ?? 0,
      refreshInterval: parseInput.readInteger() ?? 0,
      retryInterval: parseInput.readInteger() ?? 0,
      expirationTime: parseInput.readInteger() ?? 0,
      ttl: parseInput.readInteger() ?? 0
    )
  }

  private func parseMXRDataIfAvailable(_ parseInput: inout ByteBuffer) throws -> MXRecord.Data {
    MXRecord.Data(
      preference: parseInput.readInteger() ?? 0,
      exchange: try parseLabelIfAvailable(&parseInput)
    )
  }

  private func parseSRVRDataIfAvailable(_ parseInput: inout ByteBuffer) throws -> SRVRecord.Data {
    SRVRecord.Data(
      priority: parseInput.readInteger() ?? 0,
      weight: parseInput.readInteger() ?? 0,
      port: parseInput.readInteger() ?? 0,
      hostname: try parseLabelIfAvailable(&parseInput)
    )
  }

  private func parseNAPTRRDataIfAvailable(_ parseInput: inout ByteBuffer) throws -> NAPTRRecord.Data
  {
    NAPTRRecord.Data(
      order: parseInput.readInteger() ?? 0,
      preference: parseInput.readInteger() ?? 0,
      flags: try parseLengthPrefixedString(&parseInput),
      services: try parseLengthPrefixedString(&parseInput),
      regExp: try parseLengthPrefixedString(&parseInput),
      replacement: try parseLabelIfAvailable(&parseInput)
    )
  }
}
