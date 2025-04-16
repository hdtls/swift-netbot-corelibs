//
// See LICENSE.txt for license information
//

import NEAddressProcessing
import NIOCore
import Testing
import _PrettyDNS

@testable import _NEAnalytics

@Suite(.tags(.dns))
struct LocalDNSProxyTests {

  class MockDNSResolver: Resolver, @unchecked Sendable {
    var a: [ARecord] = []
    var aQueryTimes = 0

    var aaaa: [AAAARecord] = []
    var aaaaQueryTimes = 0

    var ns: [NSRecord] = []
    var nsQueryTimes = 0

    var cname: [CNAMERecord] = []
    var cnameQueryTimes = 0

    var soa: [SOARecord] = []
    var soaQueryTimes = 0

    var ptr: [PTRRecord] = []
    var ptrQueryTimes = 0

    var mx: [MXRecord] = []
    var mxQueryTimes = 0

    var txt: [TXTRecord] = []
    var txtQueryTimes = 0

    var srv: [SRVRecord] = []
    var srvQueryTimes = 0

    init(
      a: [ARecord] = [],
      aaaa: [AAAARecord] = [],
      ns: [NSRecord] = [],
      cname: [CNAMERecord] = [],
      soa: [SOARecord] = [],
      ptr: [PTRRecord] = [],
      mx: [MXRecord] = [],
      txt: [TXTRecord] = [],
      srv: [SRVRecord] = []
    ) {
      self.a = a
      self.aaaa = aaaa
      self.ns = ns
      self.cname = cname
      self.soa = soa
      self.ptr = ptr
      self.mx = mx
      self.txt = txt
      self.srv = srv
    }

    func queryA(name: String) async throws -> [ARecord] {
      aQueryTimes += 1
      return a
    }

    func queryAAAA(name: String) async throws -> [AAAARecord] {
      aaaaQueryTimes += 1
      return aaaa
    }

    func queryNS(name: String) async throws -> [NSRecord] {
      nsQueryTimes += 1
      return ns
    }

    func queryCNAME(name: String) async throws -> [CNAMERecord] {
      cnameQueryTimes += 1
      return cname
    }

    func querySOA(name: String) async throws -> [SOARecord] {
      soaQueryTimes += 1
      return soa
    }

    func queryPTR(name: String) async throws -> [PTRRecord] {
      ptrQueryTimes += 1
      return ptr
    }

    func queryMX(name: String) async throws -> [MXRecord] {
      mxQueryTimes += 1
      return mx
    }

    func queryTXT(name: String) async throws -> [TXTRecord] {
      txtQueryTimes += 1
      return txt
    }

    func querySRV(name: String) async throws -> [SRVRecord] {
      srvQueryTimes += 1
      return srv
    }
  }

  @Test func runQueryBeforeActive() async throws {
    let p = LocalDNSProxy(allocator: .init(), server: "198.18.0.1", additionalServers: ["1.1.1.1"])
    await #expect(throws: Never.self) {
      let name = "example.com"
      var result: [any ResourceRecord] = try await p.queryA(name: name)
      #expect(result.isEmpty)

      result = try await p.queryA(name: name)
      #expect(result.isEmpty)

      result = try await p.queryAAAA(name: name)
      #expect(result.isEmpty)

      result = try await p.queryNS(name: name)
      #expect(result.isEmpty)

      result = try await p.queryCNAME(name: name)
      #expect(result.isEmpty)

      result = try await p.querySOA(name: name)
      #expect(result.isEmpty)

      result = try await p.queryPTR(name: name)
      #expect(result.isEmpty)

      result = try await p.queryMX(name: name)
      #expect(result.isEmpty)

      result = try await p.queryTXT(name: name)
      #expect(result.isEmpty)

      result = try await p.querySRV(name: name)
      #expect(result.isEmpty)
    }
  }

  @Test func setResolverAfterActiveAutomatically() async throws {
    let p = LocalDNSProxy(allocator: .init(), server: "198.18.0.1", additionalServers: ["1.1.1.1"])
    await #expect(p.resolver == nil)
    try await p.runIfActive()
    await #expect(p.resolver != nil)
  }

  @Test func packetHandling() async throws {
    let p = LocalDNSProxy(server: "116.116.116.116")
    try await p.runIfActive()

    let query = try IPPacket.v4(
      .init(
        data: .init(
          plainHexEncodedBytes:
            "45000042ec3100004011dd82c0a8076674747474f0960035002e24b4cca801200001000000000001057377696674036f726700000100010000291000000000000000"
        )))

    guard case .handled(let packet) = try await p.handle(query) else {
      #expect(Bool(false), "should handle correct DNS query")
      return
    }
    guard case .v4(let response) = packet else {
      return
    }
    #expect(response.internetHeaderLength == 5)
    #expect(response.differentiatedServicesCodePoint == 0)
    #expect(response.explicitCongestionNotification == 0)
    #expect(response.totalLength == 71)
    #expect(response.flags == 0)
    #expect(response.fragmentOffset == 0)
    #expect(response.timeToLive == 5)
    #expect(response.protocol == .udp)
    #expect(response.sourceAddress == .init("116.116.116.116")!)
    #expect(response.destinationAddress == .init("192.168.7.102")!)

    let datagram = Datagram(
      data: response.payload!,
      pseudoFields: .init(
        sourceAddress: .init("116.116.116.116")!,
        destinationAddress: .init("192.168.7.102")!,
        protocol: .udp,
        dataLength: 46
      )
    )
    #expect(datagram.sourcePort == 53)
    #expect(datagram.destinationPort == 61590)
    #expect(datagram.totalLength == 51)

    let message = Message(
      headerFields: .init(
        transactionID: 0xcca8,
        flags: .init(rawValue: 0x8180),
        qestionCount: 1,
        answerCount: 1,
        authorityCount: 0,
        additionCount: 0
      ),
      questions: [Question(domainName: "swift.org", queryType: .a)],
      answerRRs: [
        ARecord(
          domainName: "swift.org", ttl: 10, dataLength: .determined(4), data: .init("198.18.0.3")!)
      ],
      authorityRRs: [],
      additionalRRs: []
    )
    let serializedBytes = try message.serializedBytes
    #expect(datagram.payload == .init(bytes: serializedBytes))
  }

  @Test func queryA() async throws {
    let p = LocalDNSProxy()
    let resolver = MockDNSResolver(
      a: [ARecord(domainName: "example.com", ttl: 300, data: .init("123.123.123.123")!)]
    )
    await p.setResolver(resolver)

    await #expect(throws: Never.self) {
      let result = try await p.queryA(name: "example.com")
      #expect(!result.isEmpty)
      #expect(resolver.aQueryTimes == 1)
      #expect(result == [resolver.a][0])

      _ = try await p.queryA(name: "example.com")
      #expect(resolver.aQueryTimes == 1)
      #expect(result == [resolver.a][0])
    }
  }

  @Test func handleExpiredARecord() async throws {
    let p = LocalDNSProxy()
    let resolver = MockDNSResolver(
      a: [ARecord(domainName: "example.com", ttl: 0, data: .init("123.123.123.123")!)]
    )
    await p.setResolver(resolver)

    await #expect(throws: Never.self) {
      let result = try await p.queryA(name: "example.com")
      #expect(!result.isEmpty)
      #expect(resolver.aQueryTimes == 1)

      _ = try await p.queryA(name: "example.com")
      #expect(resolver.aQueryTimes == 2)
    }
  }

  @Test func retryWhenCachedAQueryFailed() async throws {
    class MockAQueryResolver: MockDNSResolver, @unchecked Sendable {

      override func queryA(name: String) async throws -> [ARecord] {
        aQueryTimes += 1
        throw PrettyDNSError.notImplemented
      }
    }
    let p = LocalDNSProxy()
    let resolver = MockAQueryResolver()
    await p.setResolver(resolver)

    await #expect(throws: PrettyDNSError.self) {
      _ = try await p.queryA(name: "example.com")
      #expect(resolver.aQueryTimes == 1)
    }

    await #expect(throws: PrettyDNSError.self) {
      _ = try await p.queryA(name: "example.com")
      #expect(resolver.aQueryTimes == 2)
    }
  }

  @Test func queryAAAA() async throws {
    let p = LocalDNSProxy()
    let resolver = MockDNSResolver(
      aaaa: [AAAARecord(domainName: "example.com", ttl: 300, data: .init("::1")!)]
    )
    await p.setResolver(resolver)

    await #expect(throws: Never.self) {
      let result = try await p.queryAAAA(name: "example.com")
      #expect(!result.isEmpty)
      #expect(resolver.aaaaQueryTimes == 1)
      #expect(result == [resolver.aaaa][0])

      _ = try await p.queryAAAA(name: "example.com")
      #expect(resolver.aaaaQueryTimes == 1)
      #expect(result == [resolver.aaaa][0])
    }
  }

  @Test func handleExpiredAAAARecord() async throws {
    let p = LocalDNSProxy()
    let resolver = MockDNSResolver(
      aaaa: [AAAARecord(domainName: "example.com", ttl: 0, data: .init("::1")!)]
    )
    await p.setResolver(resolver)

    await #expect(throws: Never.self) {
      let result = try await p.queryAAAA(name: "example.com")
      #expect(!result.isEmpty)
      #expect(resolver.aaaaQueryTimes == 1)

      _ = try await p.queryAAAA(name: "example.com")
      #expect(resolver.aaaaQueryTimes == 2)
    }
  }

  @Test func retryWhenCachedAAAAQueryFailed() async throws {
    class MockAAAAQueryResolver: MockDNSResolver, @unchecked Sendable {

      override func queryAAAA(name: String) async throws -> [AAAARecord] {
        aQueryTimes += 1
        throw PrettyDNSError.notImplemented
      }
    }
    let p = LocalDNSProxy()
    let resolver = MockAAAAQueryResolver()
    await p.setResolver(resolver)

    await #expect(throws: PrettyDNSError.self) {
      _ = try await p.queryAAAA(name: "example.com")
      #expect(resolver.aaaaQueryTimes == 1)
    }

    await #expect(throws: PrettyDNSError.self) {
      _ = try await p.queryAAAA(name: "example.com")
      #expect(resolver.aaaaQueryTimes == 2)
    }
  }

  @Test func queryNS() async throws {
    let p = LocalDNSProxy()
    let resolver = MockDNSResolver(
      ns: [NSRecord(domainName: "example.com", ttl: 300, data: "1.exp.com")]
    )
    await p.setResolver(resolver)

    await #expect(throws: Never.self) {
      let result = try await p.queryNS(name: "example.com")
      #expect(!result.isEmpty)
      #expect(resolver.nsQueryTimes == 1)
      #expect(result == [resolver.ns][0])

      _ = try await p.queryNS(name: "example.com")
      #expect(resolver.nsQueryTimes == 2)
      #expect(result == [resolver.ns][0])
    }
  }

  @Test func queryCNAME() async throws {
    let p = LocalDNSProxy()
    let resolver = MockDNSResolver(
      cname: [CNAMERecord(domainName: "example.com", ttl: 300, data: "1.exp.com")]
    )
    await p.setResolver(resolver)

    await #expect(throws: Never.self) {
      let result = try await p.queryCNAME(name: "example.com")
      #expect(!result.isEmpty)
      #expect(resolver.cnameQueryTimes == 1)
      #expect(result == [resolver.cname][0])

      _ = try await p.queryCNAME(name: "example.com")
      #expect(resolver.cnameQueryTimes == 2)
      #expect(result == [resolver.cname][0])
    }
  }

  @Test func querySOA() async throws {
    let p = LocalDNSProxy()
    let resolver = MockDNSResolver(
      soa: [
        SOARecord(
          domainName: "example.com", ttl: 300,
          data: .init(
            primaryNameServer: "primary.example.com", responsibleMailbox: "mx.example.com",
            serialNumber: 0, refreshInterval: 0, retryInterval: 0, expirationTime: 0, ttl: 300))
      ]
    )
    await p.setResolver(resolver)

    await #expect(throws: Never.self) {
      let result = try await p.querySOA(name: "example.com")
      #expect(!result.isEmpty)
      #expect(resolver.soaQueryTimes == 1)
      #expect(result == [resolver.soa][0])

      _ = try await p.querySOA(name: "example.com")
      #expect(resolver.soaQueryTimes == 1)
      #expect(result == [resolver.soa][0])
    }
  }

  @Test func handleExpiredSOARecord() async throws {
    let p = LocalDNSProxy()
    let resolver = MockDNSResolver(
      soa: [
        SOARecord(
          domainName: "example.com", ttl: 0,
          data: .init(
            primaryNameServer: "primary.example.com", responsibleMailbox: "mx.example.com",
            serialNumber: 0, refreshInterval: 0, retryInterval: 0, expirationTime: 0, ttl: 0))
      ]
    )
    await p.setResolver(resolver)

    await #expect(throws: Never.self) {
      let result = try await p.querySOA(name: "example.com")
      #expect(!result.isEmpty)
      #expect(resolver.soaQueryTimes == 1)

      _ = try await p.querySOA(name: "example.com")
      #expect(resolver.soaQueryTimes == 2)
    }
  }

  @Test func retryWhenCachedSOAQueryFailed() async throws {
    class MockSOAQueryResolver: MockDNSResolver, @unchecked Sendable {

      override func querySOA(name: String) async throws -> [SOARecord] {
        soaQueryTimes += 1
        throw PrettyDNSError.notImplemented
      }
    }
    let p = LocalDNSProxy()
    let resolver = MockSOAQueryResolver()
    await p.setResolver(resolver)

    await #expect(throws: PrettyDNSError.self) {
      _ = try await p.querySOA(name: "example.com")
      #expect(resolver.soaQueryTimes == 1)
    }

    await #expect(throws: PrettyDNSError.self) {
      _ = try await p.querySOA(name: "example.com")
      #expect(resolver.soaQueryTimes == 2)
    }
  }

  @Test func queryPTR() async throws {
    let p = LocalDNSProxy()
    let resolver = MockDNSResolver(
      ptr: [PTRRecord(domainName: "example.com", ttl: 300, data: "1.exp.com")]
    )
    await p.setResolver(resolver)

    await #expect(throws: Never.self) {
      let result = try await p.queryPTR(name: "example.com")
      #expect(!result.isEmpty)
      #expect(resolver.ptrQueryTimes == 1)
      #expect(result == [resolver.ptr][0])

      _ = try await p.queryPTR(name: "example.com")
      #expect(resolver.ptrQueryTimes == 2)
      #expect(result == [resolver.ptr][0])
    }
  }

  @Test func queryMX() async throws {
    let p = LocalDNSProxy()
    let resolver = MockDNSResolver(
      mx: [
        MXRecord(
          domainName: "example.com", ttl: 300, data: .init(preference: 10, exchange: "1.exp.com"))
      ]
    )
    await p.setResolver(resolver)

    await #expect(throws: Never.self) {
      let result = try await p.queryMX(name: "example.com")
      #expect(!result.isEmpty)
      #expect(resolver.mxQueryTimes == 1)
      #expect(result == [resolver.mx][0])

      _ = try await p.queryMX(name: "example.com")
      #expect(resolver.mxQueryTimes == 2)
      #expect(result == [resolver.mx][0])
    }
  }

  @Test func queryTXT() async throws {
    let p = LocalDNSProxy()
    let resolver = MockDNSResolver(
      txt: [TXTRecord(domainName: "example.com", ttl: 300, data: "1.exp.com")]
    )
    await p.setResolver(resolver)

    await #expect(throws: Never.self) {
      let result = try await p.queryTXT(name: "example.com")
      #expect(!result.isEmpty)
      #expect(resolver.txtQueryTimes == 1)
      #expect(result == [resolver.txt][0])

      _ = try await p.queryTXT(name: "example.com")
      #expect(resolver.txtQueryTimes == 2)
      #expect(result == [resolver.txt][0])
    }
  }

  @Test func querySRV() async throws {
    let p = LocalDNSProxy()
    let resolver = MockDNSResolver(
      srv: [
        SRVRecord(
          domainName: "example.com", ttl: 300,
          data: .init(priority: 0, weight: 0, port: 33, hostname: "1.exp.com"))
      ]
    )
    await p.setResolver(resolver)

    await #expect(throws: Never.self) {
      let result = try await p.querySRV(name: "example.com")
      #expect(!result.isEmpty)
      #expect(resolver.srvQueryTimes == 1)
      #expect(result == [resolver.srv][0])

      _ = try await p.querySRV(name: "example.com")
      #expect(resolver.srvQueryTimes == 2)
      #expect(result == [resolver.srv][0])
    }
  }
}
