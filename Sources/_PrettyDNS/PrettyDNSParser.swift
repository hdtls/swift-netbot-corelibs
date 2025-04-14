//
// See LICENSE.txt for license information
//

import NEAddressProcessing
import NIOCore

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

public struct PrettyDNSParser: Sendable {

  public init() {}

  public func parse(_ parseInput: ByteBuffer) throws -> Message {
    var consumed = parseInput.readerIndex
    let headerFields = try parseHeaderFields(parseInput, consumed: &consumed)

    var questions: [Question] = []
    var numberOfLoops = headerFields.qestionCount
    while numberOfLoops > 0 {
      let question = try parseQuestion(parseInput, consumed: &consumed)
      questions.append(question)
      numberOfLoops -= 1
    }

    var answers: [any ResourceRecord] = []
    numberOfLoops = headerFields.answerCount
    while numberOfLoops > 0 {
      let answer = try parseResourceRecord(parseInput, consumed: &consumed)
      answers.append(answer)
      numberOfLoops -= 1
    }

    var authorities: [any ResourceRecord] = []
    numberOfLoops = headerFields.authorityCount
    while numberOfLoops > 0 {
      let authority = try parseResourceRecord(parseInput, consumed: &consumed)
      authorities.append(authority)
      numberOfLoops -= 1
    }

    var additionals: [any ResourceRecord] = []
    numberOfLoops = headerFields.additionCount
    while numberOfLoops > 0 {
      let additional = try parseResourceRecord(parseInput, consumed: &consumed)
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

    assert(parseInput.readableBytes == consumed)
    return message
  }

  /// Parse DNS message header from complete DNS message data and specific consumed bytes offset.
  ///
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
  private func parseHeaderFields(_ parseInput: ByteBuffer, consumed: inout Int) throws
    -> Message.HeaderFields
  {
    guard let id: UInt16 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<UInt16>.size

    guard let flags: UInt16 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<UInt16>.size

    guard let qdCount: UInt16 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<UInt16>.size

    guard let anCount: UInt16 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<UInt16>.size

    guard let nsCount: UInt16 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<UInt16>.size

    guard let arCount: UInt16 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<UInt16>.size

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

  private func parseLengthPrefixedString(_ parseInput: ByteBuffer, consumed: inout Int) throws
    -> String
  {
    guard let l: UInt8 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<UInt8>.size
    guard let parseOutput = parseInput.getString(at: consumed, length: Int(l)) else {
      throw PrettyDNSError.missingData
    }
    consumed += Int(l)
    return parseOutput
  }

  private func parseDomainName(_ parseInput: ByteBuffer, consumed: inout Int) throws -> String {
    var parseOutput = ""

    while consumed < parseInput.writerIndex {
      let lengthByte: UInt8 = parseInput.getInteger(at: consumed)!

      guard lengthByte != 0x00 else {
        // End of domain.
        consumed += MemoryLayout<UInt8>.size
        break
      }

      // Check if it's a pointer (starts with 11xxxxxx)
      if lengthByte & 0xC0 == 0xC0 {
        // It's a pointer, read the next byte too
        consumed += MemoryLayout<UInt8>.size
        guard let nextByte: UInt8 = parseInput.getInteger(at: consumed) else {
          throw PrettyDNSError.missingData
        }
        consumed += MemoryLayout<UInt8>.size
        var pointerOffset = Int(((UInt16(lengthByte & 0x3F) << 8) | UInt16(nextByte)))

        // Jump to the offset indicated by the pointer
        let label = try parseDomainName(
          parseInput, consumed: &pointerOffset)

        if parseOutput.isEmpty {
          parseOutput = label
        } else {
          parseOutput += ".\(label)"
        }
        break  // pointers are always terminal
      } else {
        // It's a label
        let label = try parseLengthPrefixedString(
          parseInput, consumed: &consumed)

        if parseOutput.isEmpty {
          parseOutput = label
        } else {
          parseOutput += ".\(label)"
        }
      }
    }

    return parseOutput
  }

  /// Parse DNS question from complete DNS message data and specific consumed bytes offset.
  ///
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
  private func parseQuestion(_ parseInput: ByteBuffer, consumed: inout Int) throws -> Question {
    let domainName = try parseDomainName(parseInput, consumed: &consumed)

    guard let qType: UInt16 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<UInt16>.size

    guard let qClass: UInt16 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<UInt16>.size

    let question = Question(
      domainName: domainName,
      queryType: .init(rawValue: qType),
      queryClass: QCLASS(rawValue: qClass)
    )

    return question
  }

  /// Parse DNS resource record from complete DNS message data and specific consumed bytes offset.
  ///
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
  private func parseResourceRecord(_ parseInput: ByteBuffer, consumed: inout Int) throws
    -> any ResourceRecord
  {
    let name = try parseDomainName(parseInput, consumed: &consumed)

    guard let rrtype: UInt16 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    let recordType = TYPE(rawValue: rrtype)
    consumed += MemoryLayout.size(ofValue: rrtype)

    guard let rrclass: UInt16 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    let dataClass = CLASS(rawValue: rrclass)
    consumed += MemoryLayout<UInt16>.size

    guard let ttl: Int32 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<Int32>.size

    guard let dataLength: UInt16 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<UInt16>.size

    guard parseInput.writerIndex >= consumed + Int(dataLength) else {
      throw PrettyDNSError.missingData
    }

    let finalize: any ResourceRecord

    switch recordType {
    case .a:
      guard let addressData = parseInput.getBytes(at: consumed, length: Int(dataLength)) else {
        throw PrettyDNSError.missingData
      }
      guard let data = IPv4Address(.init(addressData)) else {
        throw PrettyDNSError.missingData
      }
      consumed += Int(dataLength)
      finalize = ARecord(
        domainName: name,
        ttl: ttl,
        dataClass: dataClass,
        dataLength: .determined(dataLength),
        data: data
      )
    case .ns:
      finalize = NSRecord(
        domainName: name,
        ttl: ttl,
        dataClass: dataClass,
        dataLength: .determined(dataLength),
        data: try parseDomainName(parseInput, consumed: &consumed)
      )
    case .cname:
      finalize = CNAMERecord(
        domainName: name,
        ttl: ttl,
        dataClass: dataClass,
        dataLength: .determined(dataLength),
        data: try parseDomainName(parseInput, consumed: &consumed)
      )
    case .soa:
      finalize = SOARecord(
        domainName: name,
        ttl: ttl,
        dataClass: dataClass,
        dataLength: .determined(dataLength),
        data: try parseSOARData(parseInput, consumed: &consumed)
      )
    case .ptr:
      finalize = PTRRecord(
        domainName: name,
        ttl: ttl,
        dataClass: dataClass,
        dataLength: .determined(dataLength),
        data: try parseDomainName(parseInput, consumed: &consumed)
      )
    case .mx:
      finalize = MXRecord(
        domainName: name,
        ttl: ttl,
        dataClass: dataClass,
        dataLength: .determined(dataLength),
        data: try parseMXRData(parseInput, consumed: &consumed)
      )
    case .txt:
      finalize = TXTRecord(
        domainName: name,
        ttl: ttl,
        dataClass: dataClass,
        dataLength: .determined(dataLength),
        data: try parseLengthPrefixedString(parseInput, consumed: &consumed)
      )
    case .aaaa:
      guard let addressData = parseInput.getBytes(at: consumed, length: Int(dataLength)) else {
        throw PrettyDNSError.missingData
      }
      guard let data = IPv6Address(.init(addressData)) else {
        throw PrettyDNSError.missingData
      }
      consumed += Int(dataLength)
      finalize = AAAARecord(
        domainName: name,
        ttl: ttl,
        dataClass: dataClass,
        dataLength: .determined(dataLength),
        data: data
      )
    case .srv:
      finalize = SRVRecord(
        domainName: name,
        ttl: ttl,
        dataClass: dataClass,
        dataLength: .determined(dataLength),
        data: try parseSRVRData(parseInput, consumed: &consumed)
      )
    case .naptr:
      finalize = NAPTRRecord(
        domainName: name,
        ttl: ttl,
        dataClass: dataClass,
        dataLength: .determined(dataLength),
        data: try parseNAPTRRData(parseInput, consumed: &consumed)
      )
    default:
      throw PrettyDNSError.notImplemented
    }

    return finalize
  }

  private func parseSOARData(_ parseInput: ByteBuffer, consumed: inout Int) throws -> SOARecord.Data
  {
    let primaryNameServer = try parseDomainName(parseInput, consumed: &consumed)

    let responsibleMailbox = try parseDomainName(parseInput, consumed: &consumed)

    guard let serialNumber: UInt32 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<UInt32>.size

    guard let refreshInterval: UInt32 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<UInt32>.size

    guard let retryInterval: UInt32 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<UInt32>.size

    guard let expirationTime: UInt32 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<UInt32>.size

    guard let ttl: UInt32 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<UInt32>.size

    return SOARecord.Data(
      primaryNameServer: primaryNameServer,
      responsibleMailbox: responsibleMailbox,
      serialNumber: serialNumber,
      refreshInterval: refreshInterval,
      retryInterval: retryInterval,
      expirationTime: expirationTime,
      ttl: ttl
    )
  }

  private func parseMXRData(_ parseInput: ByteBuffer, consumed: inout Int) throws -> MXRecord.Data {
    guard let preference: UInt16 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<UInt16>.size

    return MXRecord.Data(
      preference: preference,
      exchange: try parseDomainName(parseInput, consumed: &consumed)
    )
  }

  private func parseSRVRData(_ parseInput: ByteBuffer, consumed: inout Int) throws -> SRVRecord.Data
  {
    guard let priority: UInt16 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<UInt16>.size

    guard let weight: UInt16 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<UInt16>.size

    guard let port: UInt16 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<UInt16>.size

    return SRVRecord.Data(
      priority: priority,
      weight: weight,
      port: port,
      hostname: try parseDomainName(parseInput, consumed: &consumed)
    )
  }

  private func parseNAPTRRData(_ parseInput: ByteBuffer, consumed: inout Int) throws
    -> NAPTRRecord.Data
  {
    guard let order: UInt16 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<UInt16>.size

    guard let preference: UInt16 = parseInput.getInteger(at: consumed) else {
      throw PrettyDNSError.missingData
    }
    consumed += MemoryLayout<UInt16>.size

    return NAPTRRecord.Data(
      order: order,
      preference: preference,
      flags: try parseLengthPrefixedString(parseInput, consumed: &consumed),
      services: try parseLengthPrefixedString(parseInput, consumed: &consumed),
      regExp: try parseLengthPrefixedString(parseInput, consumed: &consumed),
      replacement: try parseDomainName(parseInput, consumed: &consumed)
    )
  }
}
