// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

import NEAddressProcessing
import NetbotDNS
import Testing

@Suite(.tags(.dns))
struct MessageTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func createARecord() {
    let rr = ARecord(
      domainName: "swift.org",
      ttl: 300,
      dataClass: .internet,
      dataLength: .determined(4),
      data: IPv4Address("17.253.144.12")!
    )
    #expect(rr.domainName == "swift.org")
    #expect(rr.ttl == 300)
    #expect(rr.dataType == .a)
    #expect(rr.dataClass == .internet)
    #expect(rr.dataLength == .determined(4))
    #expect(rr.data == IPv4Address("17.253.144.12")!)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func createNSRecord() {
    let rr = NSRecord(
      domainName: "swift.org", ttl: 3251, dataLength: .determined(16), data: "c.ns.apple.com")
    #expect(rr.domainName == "swift.org")
    #expect(rr.ttl == 3251)
    #expect(rr.dataType == .ns)
    #expect(rr.dataClass == .internet)
    #expect(rr.dataLength == .determined(16))
    #expect(rr.data == "c.ns.apple.com")
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func createCNAMERecord() {
    let rr = CNAMERecord(
      domainName: "www.swift.org",
      ttl: 3600,
      dataLength: .determined(31),
      data: "swift.lb-apple.com.akadns.net"
    )
    #expect(rr.domainName == "www.swift.org")
    #expect(rr.ttl == 3600)
    #expect(rr.dataType == .cname)
    #expect(rr.dataClass == .internet)
    #expect(rr.dataLength == .determined(31))
    #expect(rr.data == "swift.lb-apple.com.akadns.net")
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func createSOARecord() {
    let rr = SOARecord(
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
    #expect(rr.domainName == "swift.org")
    #expect(rr.ttl == 3600)
    #expect(rr.dataType == .soa)
    #expect(rr.dataClass == .internet)
    #expect(rr.dataLength == .flexible)
    #expect(rr.data.primaryNameServer == "ns-ext-prod.jackfruit.apple.com")
    #expect(rr.data.responsibleMailbox == "hostmaster.apple.com")
    #expect(rr.data.serialNumber == 2_025_021_800)
    #expect(rr.data.refreshInterval == 1800)
    #expect(rr.data.retryInterval == 900)
    #expect(rr.data.expirationTime == 2_592_000)
    #expect(rr.data.ttl == 1800)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func createPTRRecord() {
    let rr = PTRRecord(
      domainName: "47.224.172.17.in-addr.arpa",
      ttl: 43200,
      data: "appleid.org"
    )
    #expect(rr.domainName == "47.224.172.17.in-addr.arpa")
    #expect(rr.ttl == 43200)
    #expect(rr.dataType == .ptr)
    #expect(rr.dataClass == .internet)
    #expect(rr.dataLength == .flexible)
    #expect(rr.data == "appleid.org")
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func createMXRecord() {
    let rr = MXRecord(
      domainName: "apple.com",
      ttl: 3600,
      data: .init(preference: 20, exchange: "mx-in-sg.apple.com")
    )
    #expect(rr.domainName == "apple.com")
    #expect(rr.ttl == 3600)
    #expect(rr.dataType == .mx)
    #expect(rr.dataClass == .internet)
    #expect(rr.dataLength == .flexible)
    #expect(rr.data.preference == 20)
    #expect(rr.data.exchange == "mx-in-sg.apple.com")
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func createTXTRecord() {
    let rr = TXTRecord(
      domainName: "swift.org",
      ttl: 1800,
      data: "v=DMARC1; p=none; pct=100; rua=swift-infrastructure@swift.org"
    )
    #expect(rr.domainName == "swift.org")
    #expect(rr.ttl == 1800)
    #expect(rr.dataType == .txt)
    #expect(rr.dataClass == .internet)
    #expect(rr.dataLength == .flexible)
    #expect(rr.data == "v=DMARC1; p=none; pct=100; rua=swift-infrastructure@swift.org")
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func createAAAARecord() {
    let rr = AAAARecord(
      domainName: "world-gen.g.aaplimg.com",
      ttl: 1,
      data: .init("2403:300:a04:f100::206")!
    )
    #expect(rr.domainName == "world-gen.g.aaplimg.com")
    #expect(rr.ttl == 1)
    #expect(rr.dataType == .aaaa)
    #expect(rr.dataClass == .internet)
    #expect(rr.dataLength == .flexible)
    #expect(rr.data == IPv6Address("2403:300:a04:f100::206")!)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func createSRVRecord() {
    let rr = SRVRecord(
      domainName: "_caldavs._tcp.google.com",
      ttl: 12475,
      data: .init(priority: 5, weight: 0, port: 443, hostname: "calendar.google.com")
    )
    #expect(rr.domainName == "_caldavs._tcp.google.com")
    #expect(rr.ttl == 12475)
    #expect(rr.dataType == .srv)
    #expect(rr.dataClass == .internet)
    #expect(rr.dataLength == .flexible)
    #expect(rr.data.priority == 5)
    #expect(rr.data.weight == 0)
    #expect(rr.data.port == 443)
    #expect(rr.data.hostname == "calendar.google.com")
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func createNAPTRRecord() {
    let rr = NAPTRRecord(
      domainName: "example.com",
      ttl: 60,
      data: .init(
        order: 100, preference: 10, flags: "u", services: "E2U+sip",
        regExp: "!^.*$!sip:info@example.com!", replacement: "srv.example.com")
    )
    #expect(rr.domainName == "example.com")
    #expect(rr.ttl == 60)
    #expect(rr.dataType == .naptr)
    #expect(rr.dataClass == .internet)
    #expect(rr.dataLength == .flexible)
    #expect(rr.data.order == 100)
    #expect(rr.data.preference == 10)
    #expect(rr.data.flags == "u")
    #expect(rr.data.services == "E2U+sip")
    #expect(rr.data.regExp == "!^.*$!sip:info@example.com!")
    #expect(rr.data.replacement == "srv.example.com")
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func createQuestion() {
    let q = Question(domainName: "swift.org", queryType: .a, queryClass: .chaos)
    #expect(q.domainName == "swift.org")
    #expect(q.queryType == .a)
    #expect(q.queryClass == .chaos)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func createMessage() {
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

    let headerFields = Message.HeaderFields(
      transactionID: 0x1165,
      flags: .init(rawValue: 0x8180),
      questionCount: UInt16(questions.count),
      answerCount: UInt16(answerRRs.count),
      authorityCount: 0,
      additionCount: 0
    )

    let message = Message(
      headerFields: .init(
        transactionID: 0x1165,
        flags: .init(rawValue: 0x8180),
        questionCount: UInt16(questions.count),
        answerCount: UInt16(answerRRs.count),
        authorityCount: 0,
        additionCount: 0
      ),
      questions: questions,
      answerRRs: answerRRs,
      authorityRRs: [],
      additionalRRs: []
    )

    #expect(message.headerFields == headerFields)
    #expect(message.questions == questions)
    #expect(message.answerRRs as! [ARecord] == answerRRs)
    #expect(message.authorityRRs.isEmpty)
    #expect(message.additionalRRs.isEmpty)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func createMessageUsingConvenienceInitializer() {
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

    let headerFields = Message.HeaderFields(
      transactionID: 0x1165,
      flags: .init(rawValue: 0x8180),
      questionCount: UInt16(questions.count),
      answerCount: UInt16(answerRRs.count),
      authorityCount: 0,
      additionCount: 0
    )

    let message = Message(
      transactionID: 0x1165,
      response: true,
      recursionDesired: true,
      recursionAvailable: true,
      questions: questions,
      answerRRs: answerRRs,
      authorityRRs: [],
      additionalRRs: []
    )

    #expect(message.headerFields == headerFields)
    #expect(message.questions == questions)
    #expect(message.answerRRs as! [ARecord] == answerRRs)
    #expect(message.authorityRRs.isEmpty)
    #expect(message.additionalRRs.isEmpty)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func headerFieldsInitializer() {
    let fields = Message.HeaderFields(
      transactionID: 0,
      flags: .init(rawValue: 0x8181),
      questionCount: 0,
      answerCount: 0,
      authorityCount: 0,
      additionCount: 0
    )
    #expect(fields.transactionID == 0)
    #expect(fields.flags == .init(rawValue: 0x8181))
    #expect(fields.questionCount == 0)
    #expect(fields.answerCount == 0)
    #expect(fields.authorityCount == 0)
    #expect(fields.additionCount == 0)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func messageHeaderFlagsInitializer() {
    var flags = Message.HeaderFields.Flags(rawValue: 0x8180)
    #expect(flags.isResponse)
    #expect(flags.operationCode == .query)
    #expect(!flags.isAuthoritative)
    #expect(!flags.isTruncated)
    #expect(flags.recursionDesired)
    #expect(flags.recursionAvailable)
    #expect(!flags.authenticatedData)
    #expect(!flags.checkingDisabled)
    #expect(flags.responseCode == .noError)

    flags = Message.HeaderFields.Flags(
      response: true,
      operationCode: .query,
      authoritative: false,
      truncated: false,
      recursionDesired: true,
      recursionAvailable: true,
      authenticatedData: false,
      checkingDisabled: false,
      responseCode: .noError
    )
    #expect(flags.rawValue == 0x8180)
    #expect(flags.isResponse)
    #expect(flags.operationCode == .query)
    #expect(!flags.isAuthoritative)
    #expect(!flags.isTruncated)
    #expect(flags.recursionDesired)
    #expect(flags.recursionAvailable)
    #expect(!flags.authenticatedData)
    #expect(!flags.checkingDisabled)
    #expect(flags.responseCode == .noError)
  }
}
