// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import NEAddressProcessing
import NIOCore
import Testing

@testable import _DNSSupport

@Suite(.tags(.dns))
struct PrettyDNSTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  private var parser: NLDNSParser { NLDNSParser() }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func parseAResponse() async throws {
    let answerRRs = [
      ARecord(
        domainName: "swift.org",
        ttl: 1,
        dataLength: .determined(4),
        data: .init("17.253.144.12")!
      )
    ]

    let questions = [
      Question(domainName: "swift.org", queryType: .a)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0x1165,
        flags: .init(rawValue: 0x8180),
        qestionCount: UInt16(questions.count),
        answerCount: UInt16(answerRRs.count),
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
        "116581800001000100000000057377696674036f72670000010001c00c0001000100000001000411fd900c"
    )

    #expect(throws: Never.self) {
      let parseOutput = try parser.parse(parseInput)
      #expect(parseOutput.headerFields == message.headerFields)
      #expect(parseOutput.questions == questions)
      #expect(parseOutput.answerRRs as? [ARecord] == answerRRs)
      #expect(parseOutput.authorityRRs.isEmpty)
      #expect(parseOutput.additionalRRs.isEmpty)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func serializeAResponse() async throws {
    let answerRRs = [
      ARecord(
        domainName: "swift.org",
        ttl: 1,
        dataLength: .determined(4),
        data: .init("17.253.144.12")!
      )
    ]

    let questions = [
      Question(domainName: "swift.org", queryType: .a)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0x1165,
        flags: .init(rawValue: 0x8180),
        qestionCount: UInt16(questions.count),
        answerCount: UInt16(answerRRs.count),
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
        "116581800001000100000000057377696674036f72670000010001c00c0001000100000001000411fd900c"
    )

    #expect(throws: Never.self) {
      let serializedBytes = try message.serializedBytes
      #expect(ByteBuffer(bytes: serializedBytes) == parseInput)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func parseNSResponse() async throws {
    let answerRRs = [
      NSRecord(
        domainName: "swift.org", ttl: 3251, dataLength: .determined(16), data: "c.ns.apple.com"),
      NSRecord(
        domainName: "swift.org", ttl: 3251, dataLength: .determined(4), data: "b.ns.apple.com"),
      NSRecord(
        domainName: "swift.org", ttl: 3251, dataLength: .determined(4), data: "d.ns.apple.com"),
      NSRecord(
        domainName: "swift.org", ttl: 3251, dataLength: .determined(4), data: "a.ns.apple.com"),
    ]

    let questions = [
      Question(domainName: "swift.org", queryType: .ns)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0x87da,
        flags: .init(rawValue: 0x8180),
        qestionCount: UInt16(questions.count),
        answerCount: UInt16(answerRRs.count),
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
        "87da81800001000400000000057377696674036f72670000020001c00c0002000100000cb300100163026e73056170706c6503636f6d00c00c0002000100000cb300040162c029c00c0002000100000cb300040164c029c00c0002000100000cb300040161c029"
    )

    #expect(throws: Never.self) {
      let parseOutput = try parser.parse(parseInput)
      #expect(parseOutput.headerFields == message.headerFields)
      #expect(parseOutput.questions == questions)
      #expect(parseOutput.answerRRs as? [NSRecord] == answerRRs)
      #expect(parseOutput.authorityRRs.isEmpty)
      #expect(parseOutput.additionalRRs.isEmpty)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func serializeNSResponse() async throws {
    let answerRRs = [
      NSRecord(domainName: "swift.org", ttl: 3251, data: "c.ns.apple.com"),
      NSRecord(domainName: "swift.org", ttl: 3251, data: "b.ns.apple.com"),
      NSRecord(domainName: "swift.org", ttl: 3251, data: "d.ns.apple.com"),
      NSRecord(domainName: "swift.org", ttl: 3251, data: "a.ns.apple.com"),
    ]

    let questions = [
      Question(domainName: "swift.org", queryType: .ns)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0x87da,
        flags: .init(rawValue: 0x8180),
        qestionCount: UInt16(questions.count),
        answerCount: UInt16(answerRRs.count),
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
        "87da81800001000400000000057377696674036f72670000020001c00c0002000100000cb300100163026e73056170706c6503636f6d00c00c0002000100000cb300040162c029c00c0002000100000cb300040164c029c00c0002000100000cb300040161c029"
    )

    #expect(throws: Never.self) {
      let serializedBytes = try message.serializedBytes
      #expect(
        ByteBuffer(bytes: serializedBytes).hexDump(format: .detailed)
          == parseInput.hexDump(
            format: .detailed
          ))
      #expect(ByteBuffer(bytes: serializedBytes) == parseInput)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func parseCNAMEResponse() async throws {
    let answerRRs = [
      CNAMERecord(
        domainName: "www.swift.org",
        ttl: 3600,
        dataLength: .determined(31),
        data: "swift.lb-apple.com.akadns.net"
      )
    ]

    let questions = [
      Question(domainName: "www.swift.org", queryType: .cname)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0xa819,
        flags: .init(rawValue: 0x8180),
        qestionCount: UInt16(questions.count),
        answerCount: UInt16(answerRRs.count),
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
        "a8198180000100010000000003777777057377696674036f72670000050001c00c0005000100000e10001f057377696674086c622d6170706c6503636f6d06616b61646e73036e657400"
    )

    #expect(throws: Never.self) {
      let parseOutput = try parser.parse(parseInput)
      #expect(parseOutput.headerFields == message.headerFields)
      #expect(parseOutput.questions == questions)
      #expect(parseOutput.answerRRs as? [CNAMERecord] == answerRRs)
      #expect(parseOutput.authorityRRs.isEmpty)
      #expect(parseOutput.additionalRRs.isEmpty)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func serializeCNAMEResponse() async throws {
    let answerRRs = [
      CNAMERecord(
        domainName: "www.swift.org",
        ttl: 3600,
        dataLength: .determined(31),
        data: "swift.lb-apple.com.akadns.net"
      )
    ]

    let questions = [
      Question(domainName: "www.swift.org", queryType: .cname)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0xa819,
        flags: .init(rawValue: 0x8180),
        qestionCount: UInt16(questions.count),
        answerCount: UInt16(answerRRs.count),
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
        "a8198180000100010000000003777777057377696674036f72670000050001c00c0005000100000e10001f057377696674086c622d6170706c6503636f6d06616b61646e73036e657400"
    )

    #expect(throws: Never.self) {
      let serializedBytes = try message.serializedBytes
      #expect(ByteBuffer(bytes: serializedBytes) == parseInput)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func parseSOAResponse() async throws {
    let answerRRs = [
      SOARecord(
        domainName: "swift.org",
        ttl: 3600,
        dataLength: .determined(66),
        data: .init(
          primaryNameServer: "ns-ext-prod.jackfruit.apple.com",
          responsibleMailbox: "hostmaster.apple.com",
          serialNumber: 2_025_021_800,
          refreshInterval: 1800,
          retryInterval: 900,
          expirationTime: 2_592_000,
          ttl: 1800
        )
      )
    ]

    let questions = [
      Question(domainName: "swift.org", queryType: .soa)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0xfb68,
        flags: .init(rawValue: 0x8180),
        qestionCount: UInt16(questions.count),
        answerCount: UInt16(answerRRs.count),
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
        "fb6881800001000100000000057377696674036f72670000060001c00c0006000100000e1000420b6e732d6578742d70726f64096a61636b6672756974056170706c6503636f6d000a686f73746d6173746572c03d78b36168000007080000038400278d0000000708"
    )

    #expect(throws: Never.self) {
      let parseOutput = try parser.parse(parseInput)
      #expect(parseOutput.headerFields == message.headerFields)
      #expect(parseOutput.questions == questions)
      #expect(parseOutput.answerRRs as? [SOARecord] == answerRRs)
      #expect(parseOutput.authorityRRs.isEmpty)
      #expect(parseOutput.additionalRRs.isEmpty)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func serializeSOAResponse() async throws {
    let answerRRs = [
      SOARecord(
        domainName: "swift.org",
        ttl: 3600,
        data: .init(
          primaryNameServer: "ns-ext-prod.jackfruit.apple.com",
          responsibleMailbox: "hostmaster.apple.com",
          serialNumber: 2_025_021_800,
          refreshInterval: 1800,
          retryInterval: 900,
          expirationTime: 2_592_000,
          ttl: 1800
        )
      )
    ]

    let questions = [
      Question(domainName: "swift.org", queryType: .soa)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0xfb68,
        flags: .init(rawValue: 0x8180),
        qestionCount: UInt16(questions.count),
        answerCount: UInt16(answerRRs.count),
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
        "fb6881800001000100000000057377696674036f72670000060001c00c0006000100000e1000420b6e732d6578742d70726f64096a61636b6672756974056170706c6503636f6d000a686f73746d6173746572c03d78b36168000007080000038400278d0000000708"
    )

    #expect(throws: Never.self) {
      let serializedBytes = try message.serializedBytes
      #expect(ByteBuffer(bytes: serializedBytes) == parseInput)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func parsePTRResponse() async throws {
    let answerRRs = [
      PTRRecord(
        domainName: "47.224.172.17.in-addr.arpa",
        ttl: 43200,
        dataLength: .determined(13),
        data: "appleid.org"
      )
    ]

    let questions = [
      Question(domainName: "47.224.172.17.in-addr.arpa", queryType: .ptr)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0xf2b9,
        flags: .init(rawValue: 0x8180),
        qestionCount: UInt16(questions.count),
        answerCount: UInt16(answerRRs.count),
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
        "f2b981800001000100000000023437033232340331373202313707696e2d61646472046172706100000c0001c00c000c00010000a8c0000d076170706c656964036f726700"
    )

    #expect(throws: Never.self) {
      let parseOutput = try parser.parse(parseInput)
      #expect(parseOutput.headerFields == message.headerFields)
      #expect(parseOutput.questions == questions)
      #expect(parseOutput.answerRRs as? [PTRRecord] == answerRRs)
      #expect(parseOutput.authorityRRs.isEmpty)
      #expect(parseOutput.additionalRRs.isEmpty)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func serializePTRResponse() async throws {
    let answerRRs = [
      PTRRecord(
        domainName: "47.224.172.17.in-addr.arpa",
        ttl: 43200,
        data: "appleid.org"
      )
    ]

    let questions = [
      Question(domainName: "47.224.172.17.in-addr.arpa", queryType: .ptr)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0xf2b9,
        flags: .init(rawValue: 0x8180),
        qestionCount: UInt16(questions.count),
        answerCount: UInt16(answerRRs.count),
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
        "f2b981800001000100000000023437033232340331373202313707696e2d61646472046172706100000c0001c00c000c00010000a8c0000d076170706c656964036f726700"
    )

    #expect(throws: Never.self) {
      let serializedBytes = try message.serializedBytes
      #expect(ByteBuffer(bytes: serializedBytes) == parseInput)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func parseMXResponse() async throws {
    let answerRRs = [
      MXRecord(
        domainName: "apple.com",
        ttl: 3600,
        dataLength: .determined(13),
        data: .init(preference: 20, exchange: "mx-in-sg.apple.com")
      ),
      MXRecord(
        domainName: "apple.com",
        ttl: 3600,
        dataLength: .determined(14),
        data: .init(preference: 20, exchange: "mx-in-hfd.apple.com")
      ),
      MXRecord(
        domainName: "apple.com",
        ttl: 3600,
        dataLength: .determined(13),
        data: .init(preference: 20, exchange: "mx-in-rn.apple.com")
      ),
      MXRecord(
        domainName: "apple.com",
        ttl: 3600,
        dataLength: .determined(13),
        data: .init(preference: 20, exchange: "mx-in-ma.apple.com")
      ),
      MXRecord(
        domainName: "apple.com",
        ttl: 3600,
        dataLength: .determined(12),
        data: .init(preference: 10, exchange: "mx-in.g.apple.com")
      ),
      MXRecord(
        domainName: "apple.com",
        ttl: 3600,
        dataLength: .determined(14),
        data: .init(preference: 20, exchange: "mx-in-vib.apple.com")
      ),
    ]

    let questions = [
      Question(domainName: "apple.com", queryType: .mx)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0xb441,
        flags: .init(rawValue: 0x8180),
        qestionCount: UInt16(questions.count),
        answerCount: UInt16(answerRRs.count),
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
        "b44181800001000600000000056170706c6503636f6d00000f0001c00c000f000100000e10000d0014086d782d696e2d7367c00cc00c000f000100000e10000e0014096d782d696e2d686664c00cc00c000f000100000e10000d0014086d782d696e2d726ec00cc00c000f000100000e10000d0014086d782d696e2d6d61c00cc00c000f000100000e10000c000a056d782d696e0167c00cc00c000f000100000e10000e0014096d782d696e2d766962c00c"
    )

    #expect(throws: Never.self) {
      let parseOutput = try parser.parse(parseInput)
      #expect(parseOutput.headerFields == message.headerFields)
      #expect(parseOutput.questions == questions)
      #expect(parseOutput.answerRRs as? [MXRecord] == answerRRs)
      #expect(parseOutput.authorityRRs.isEmpty)
      #expect(parseOutput.additionalRRs.isEmpty)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func serializeMXResponse() async throws {
    let answerRRs = [
      MXRecord(
        domainName: "apple.com",
        ttl: 3600,
        data: .init(preference: 20, exchange: "mx-in-sg.apple.com")
      ),
      MXRecord(
        domainName: "apple.com",
        ttl: 3600,
        data: .init(preference: 20, exchange: "mx-in-hfd.apple.com")
      ),
      MXRecord(
        domainName: "apple.com",
        ttl: 3600,
        data: .init(preference: 20, exchange: "mx-in-rn.apple.com")
      ),
      MXRecord(
        domainName: "apple.com",
        ttl: 3600,
        data: .init(preference: 20, exchange: "mx-in-ma.apple.com")
      ),
      MXRecord(
        domainName: "apple.com",
        ttl: 3600,
        data: .init(preference: 10, exchange: "mx-in.g.apple.com")
      ),
      MXRecord(
        domainName: "apple.com",
        ttl: 3600,
        data: .init(preference: 20, exchange: "mx-in-vib.apple.com")
      ),
    ]

    let questions = [
      Question(domainName: "apple.com", queryType: .mx)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0xb441,
        flags: .init(rawValue: 0x8180),
        qestionCount: UInt16(questions.count),
        answerCount: UInt16(answerRRs.count),
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
        "b44181800001000600000000056170706c6503636f6d00000f0001c00c000f000100000e10000d0014086d782d696e2d7367c00cc00c000f000100000e10000e0014096d782d696e2d686664c00cc00c000f000100000e10000d0014086d782d696e2d726ec00cc00c000f000100000e10000d0014086d782d696e2d6d61c00cc00c000f000100000e10000c000a056d782d696e0167c00cc00c000f000100000e10000e0014096d782d696e2d766962c00c"
    )

    #expect(throws: Never.self) {
      let serializedBytes = try message.serializedBytes
      #expect(ByteBuffer(bytes: serializedBytes) == parseInput)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func parseTXTResponse() async throws {
    let answerRRs = [
      TXTRecord(
        domainName: "swift.org",
        ttl: 1800,
        dataLength: .determined(62),
        data: "v=DMARC1; p=none; pct=100; rua=swift-infrastructure@swift.org"
      ),
      TXTRecord(
        domainName: "swift.org",
        ttl: 1800,
        dataLength: .determined(12),
        data: "v=spf1 -all"
      ),
      TXTRecord(
        domainName: "swift.org",
        ttl: 1800,
        dataLength: .determined(33),
        data: "cd60njgdwlpyyg36ptypc2jqhb1nrqt9"
      ),
    ]

    let questions = [
      Question(domainName: "swift.org", queryType: .txt)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0x0ec5,
        flags: .init(rawValue: 0x8180),
        qestionCount: UInt16(questions.count),
        answerCount: UInt16(answerRRs.count),
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
        "0ec581800001000300000000057377696674036f72670000100001c00c0010000100000708003e3d763d444d415243313b20703d6e6f6e653b207063743d3130303b207275613d73776966742d696e6672617374727563747572654073776966742e6f7267c00c0010000100000708000c0b763d73706631202d616c6cc00c0010000100000708002120636436306e6a6764776c7079796733367074797063326a716862316e72717439"
    )

    #expect(throws: Never.self) {
      let parseOutput = try parser.parse(parseInput)
      #expect(parseOutput.headerFields == message.headerFields)
      #expect(parseOutput.questions == questions)
      #expect(parseOutput.answerRRs as? [TXTRecord] == answerRRs)
      #expect(parseOutput.authorityRRs.isEmpty)
      #expect(parseOutput.additionalRRs.isEmpty)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func serializeTXTResponse() async throws {
    let answerRRs = [
      TXTRecord(
        domainName: "swift.org",
        ttl: 1800,
        data: "v=DMARC1; p=none; pct=100; rua=swift-infrastructure@swift.org"
      ),
      TXTRecord(
        domainName: "swift.org",
        ttl: 1800,
        data: "v=spf1 -all"
      ),
      TXTRecord(
        domainName: "swift.org",
        ttl: 1800,
        data: "cd60njgdwlpyyg36ptypc2jqhb1nrqt9"
      ),
    ]

    let questions = [
      Question(domainName: "swift.org", queryType: .txt)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0x0ec5,
        flags: .init(rawValue: 0x8180),
        qestionCount: UInt16(questions.count),
        answerCount: UInt16(answerRRs.count),
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
        "0ec581800001000300000000057377696674036f72670000100001c00c0010000100000708003e3d763d444d415243313b20703d6e6f6e653b207063743d3130303b207275613d73776966742d696e6672617374727563747572654073776966742e6f7267c00c0010000100000708000c0b763d73706631202d616c6cc00c0010000100000708002120636436306e6a6764776c7079796733367074797063326a716862316e72717439"
    )

    #expect(throws: Never.self) {
      let serializedBytes = try message.serializedBytes
      #expect(ByteBuffer(bytes: serializedBytes) == parseInput)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func parseAAAAResponse() async throws {
    let answerRRs: [any ResourceRecord] = [
      CNAMERecord(
        domainName: "www.swift.org",
        ttl: 1,
        dataLength: .determined(31),
        data: "swift.lb-apple.com.akadns.net"
      ),
      CNAMERecord(
        domainName: "swift.lb-apple.com.akadns.net",
        ttl: 1,
        dataLength: .determined(25),
        data: "world-gen.g.aaplimg.com"
      ),
      AAAARecord(
        domainName: "world-gen.g.aaplimg.com",
        ttl: 1,
        dataLength: .determined(16),
        data: .init("2403:300:a04:f100::206")!
      ),
      AAAARecord(
        domainName: "world-gen.g.aaplimg.com",
        ttl: 1,
        dataLength: .determined(16),
        data: .init("2403:300:a04:f100::204")!
      ),
    ]

    let questions = [
      Question(domainName: "www.swift.org", queryType: .aaaa)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0x6bc8,
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
        "6bc88180000100040000000003777777057377696674036f726700001c0001c00c0005000100000001001f057377696674086c622d6170706c6503636f6d06616b61646e73036e657400c02b0005000100000001001909776f726c642d67656e0167076161706c696d6703636f6d00c056001c0001000000010010240303000a04f1000000000000000206c056001c0001000000010010240303000a04f1000000000000000204"
    )

    #expect(throws: Never.self) {
      let parseOutput = try parser.parse(parseInput)
      #expect(parseOutput.headerFields == message.headerFields)
      #expect(parseOutput.questions == questions)
      #expect(parseOutput.answerRRs.count == 4)
      #expect(answerRRs[0] as? CNAMERecord == parseOutput.answerRRs[0] as? CNAMERecord)
      #expect(answerRRs[1] as? CNAMERecord == parseOutput.answerRRs[1] as? CNAMERecord)
      #expect(answerRRs[2] as? AAAARecord == parseOutput.answerRRs[2] as? AAAARecord)
      #expect(answerRRs[3] as? AAAARecord == parseOutput.answerRRs[3] as? AAAARecord)
      #expect(parseOutput.authorityRRs.isEmpty)
      #expect(parseOutput.additionalRRs.isEmpty)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func serializeAAAAResponse() async throws {
    let answerRRs: [any ResourceRecord] = [
      CNAMERecord(
        domainName: "www.swift.org",
        ttl: 1,
        data: "swift.lb-apple.com.akadns.net"
      ),
      CNAMERecord(
        domainName: "swift.lb-apple.com.akadns.net",
        ttl: 1,
        data: "world-gen.g.aaplimg.com"
      ),
      AAAARecord(
        domainName: "world-gen.g.aaplimg.com",
        ttl: 1,
        data: .init("2403:300:a04:f100::206")!
      ),
      AAAARecord(
        domainName: "world-gen.g.aaplimg.com",
        ttl: 1,
        data: .init("2403:300:a04:f100::204")!
      ),
    ]

    let questions = [
      Question(domainName: "www.swift.org", queryType: .aaaa)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0x6bc8,
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
        "6bc88180000100040000000003777777057377696674036f726700001c0001c00c0005000100000001001f057377696674086c622d6170706c6503636f6d06616b61646e73036e657400c02b0005000100000001001909776f726c642d67656e0167076161706c696d6703636f6d00c056001c0001000000010010240303000a04f1000000000000000206c056001c0001000000010010240303000a04f1000000000000000204"
    )

    #expect(throws: Never.self) {
      let serializedBytes = try message.serializedBytes
      #expect(ByteBuffer(bytes: serializedBytes) == parseInput)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func parseSRVResponse() async throws {
    let answerRRs = [
      SRVRecord(
        domainName: "_caldavs._tcp.google.com",
        ttl: 12475,
        dataLength: .determined(27),
        data: .init(priority: 5, weight: 0, port: 443, hostname: "calendar.google.com")
      )
    ]

    let questions = [
      Question(domainName: "_caldavs._tcp.google.com", queryType: .srv)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0xde83,
        flags: .init(rawValue: 0x8180),
        qestionCount: UInt16(questions.count),
        answerCount: UInt16(answerRRs.count),
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
        "de8381800001000100000000085f63616c64617673045f74637006676f6f676c6503636f6d0000210001c00c00210001000030bb001b0005000001bb0863616c656e64617206676f6f676c6503636f6d00"
    )

    #expect(throws: Never.self) {
      let parseOutput = try parser.parse(parseInput)
      #expect(parseOutput.headerFields == message.headerFields)
      #expect(parseOutput.questions == questions)
      #expect(parseOutput.answerRRs as? [SRVRecord] == answerRRs)
      #expect(parseOutput.authorityRRs.isEmpty)
      #expect(parseOutput.additionalRRs.isEmpty)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func serializeSRVResponse() async throws {
    let answerRRs = [
      SRVRecord(
        domainName: "_caldavs._tcp.google.com",
        ttl: 12475,
        data: .init(priority: 5, weight: 0, port: 443, hostname: "calendar.google.com")
      )
    ]

    let questions = [
      Question(domainName: "_caldavs._tcp.google.com", queryType: .srv)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0xde83,
        flags: .init(rawValue: 0x8180),
        qestionCount: UInt16(questions.count),
        answerCount: UInt16(answerRRs.count),
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
        "de8381800001000100000000085f63616c64617673045f74637006676f6f676c6503636f6d0000210001c00c00210001000030bb00110005000001bb0863616c656e646172c01a"
    )

    #expect(throws: Never.self) {
      let serializedBytes = try message.serializedBytes
      #expect(ByteBuffer(bytes: serializedBytes) == parseInput)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func parseNAPTRResponse() async throws {
    let answerRRs = [
      NAPTRRecord(
        domainName: "example.com",
        ttl: 60,
        dataLength: .determined(48),
        data: .init(
          order: 100, preference: 10, flags: "u", services: "E2U+sip",
          regExp: "!^.*$!sip:info@example.com!", replacement: "srv.example.com")
      )
    ]

    let questions = [
      Question(domainName: "example.com", queryType: .naptr)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0xaaaa,
        flags: .init(rawValue: 0x8180),
        qestionCount: UInt16(questions.count),
        answerCount: UInt16(answerRRs.count),
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
        "aaaa81800001000100000000076578616d706c6503636f6d0000230001c00c002300010000003c00300064000a0175074532552b7369701b215e2e2a24217369703a696e666f406578616d706c652e636f6d2103737276c00c"
    )

    #expect(throws: Never.self) {
      let parseOutput = try parser.parse(parseInput)
      #expect(parseOutput.headerFields == message.headerFields)
      #expect(parseOutput.questions == questions)
      #expect(parseOutput.answerRRs as? [NAPTRRecord] == answerRRs)
      #expect(parseOutput.authorityRRs.isEmpty)
      #expect(parseOutput.additionalRRs.isEmpty)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func serializeNAPTRResponse() async throws {
    let answerRRs = [
      NAPTRRecord(
        domainName: "example.com",
        ttl: 60,
        dataLength: .determined(48),
        data: .init(
          order: 100, preference: 10, flags: "u", services: "E2U+sip",
          regExp: "!^.*$!sip:info@example.com!", replacement: "srv.example.com")
      )
    ]

    let questions = [
      Question(domainName: "example.com", queryType: .naptr)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0xaaaa,
        flags: .init(rawValue: 0x8180),
        qestionCount: UInt16(questions.count),
        answerCount: UInt16(answerRRs.count),
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
        "aaaa81800001000100000000076578616d706c6503636f6d0000230001c00c002300010000003c00300064000a0175074532552b7369701b215e2e2a24217369703a696e666f406578616d706c652e636f6d2103737276c00c"
    )

    #expect(throws: Never.self) {
      let serializedBytes = try message.serializedBytes
      #expect(ByteBuffer(bytes: serializedBytes) == parseInput)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func serializeEmptyDomainInRR() async throws {
    let answerRRs = [
      CNAMERecord(
        domainName: "example.com",
        ttl: 60,
        dataLength: .determined(0),
        data: ""
      )
    ]

    let questions = [
      Question(domainName: "example.com", queryType: .cname)
    ]

    let message = Message(
      headerFields: .init(
        transactionID: 0xaaaa,
        flags: .init(rawValue: 0x8180),
        qestionCount: UInt16(questions.count),
        answerCount: UInt16(answerRRs.count),
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
        "aaaa81800001000100000000076578616d706c6503636f6d0000050001c00c000500010000003c000100"
    )

    #expect(throws: Never.self) {
      let serializedBytes = try message.serializedBytes
      #expect(ByteBuffer(bytes: serializedBytes) == parseInput)
    }
  }
}
