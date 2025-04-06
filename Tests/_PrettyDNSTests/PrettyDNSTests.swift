//
// See LICENSE.txt for license information
//

import NIOCore
import Testing

@testable import _PrettyDNS

@Suite(.tags(.dns))
struct PrettyDNSTests {

  private let parser = DNSParser()

  //  @Test func parseLabel() async throws {
  //    var parseInput = try ByteBuffer(plainHexEncodedBytes: "04696d61700665786d61696c02717103636f6d00")
  //    let parseOutput = try parser.parseLabelIfAvailable(&parseInput)
  //    #expect(parseOutput == "imap.exmail.qq.com")
  //    #expect(parseInput.readableBytes == 0)
  //  }
  //
  //  @Test func parseQuestion() async throws {
  //    var parseInput = try ByteBuffer(plainHexEncodedBytes: "04696d61700665786d61696c02717103636f6d0000010001")
  //    let parseOutput = try parser.parseQuestionIfAvailable(&parseInput)
  //
  //    let expected = Question(domainName: "imap.exmail.qq.com", queryType: .a, queryClass: .internet)
  //
  //    #expect(parseOutput == expected)
  //    #expect(parseInput.readableBytes == 0)
  //  }
  //
  //  @Test func parseARecord() async throws {
  //    var parseInput = try ByteBuffer(plainHexEncodedBytes: "c00c0001000100000258000424f82d27")
  //    let parseOutput = try parser.parseRRIfAvailable(&parseInput)
  //
  //    let expected = ARecord(
  //      ownerName: "imap.exmail.qq.com",
  //      recordType: .a,
  //      recordClass: .internet,
  //      ttl: 600,
  //      data: .init("36.248.45.39")!
  //    )
  //
  //    #expect(parseOutput as? ARecord == expected)
  //    #expect(parseInput.readableBytes == 0)
  //  }

  @Test func aRecordParseAndSerializing() async throws {
    let answerRRs = [
      ARecord(
        ownerName: "imap.exmail.qq.com",
        recordType: .a,
        recordClass: .internet,
        ttl: 600,
        data: .init("36.248.45.39")!
      ),
      ARecord(
        ownerName: "imap.exmail.qq.com",
        recordType: .a,
        recordClass: .internet,
        ttl: 600,
        data: .init("36.248.45.46")!
      ),
      ARecord(
        ownerName: "imap.exmail.qq.com",
        recordType: .a,
        recordClass: .internet,
        ttl: 600,
        data: .init("116.162.46.161")!
      ),
      ARecord(
        ownerName: "imap.exmail.qq.com",
        recordType: .a,
        recordClass: .internet,
        ttl: 600,
        data: .init("116.162.34.33")!
      ),
    ]

    let questions = [
      Question(domainName: "imap.exmail.qq.com", queryType: .a, queryClass: .internet)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0xbc65,
        flags: .init(rawValue: 0x8180),
        qestionCount: 1,
        answerCount: 4,
        authorityCount: 0,
        additionCount: 0
      ),
      questions: questions,
      answerRRs: answerRRs,
      authorityRRs: [],
      additionalRRs: []
    )

    let parseInput = try ByteBuffer(
      plainHexEncodedBytes:
        "bc658180000100040000000004696d61700665786d61696c02717103636f6d0000010001c00c0001000100000258000424f82d27c00c0001000100000258000424f82d2ec00c0001000100000258000474a22ea1c00c0001000100000258000474a22221"
    )

    let parseOutput = try parser.parse(parseInput)
    #expect(parseOutput.headerFields == message.headerFields)
    #expect(parseOutput.questions == questions)
    #expect(parseOutput.answerRRs.count == 4)
    for (i, answerRR) in parseOutput.answerRRs.enumerated() {
      #expect(answerRRs[i] == answerRR as? ARecord)
    }
    #expect(parseOutput.authorityRRs.isEmpty)
    #expect(parseOutput.additionalRRs.isEmpty)
  }
}
