//
// See LICENSE.txt for license information
//

#if DEBUG
  import Netbot
  import SwiftData

  extension ModelContainer {

    static var preview: ModelContainer {
      get throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let schema: Schema = Schema(versionedSchema: V1.self)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return container
      }
    }
  }

  extension Profile.PersistentModel {

    static var preview: Profile.PersistentModel {
      let perisistentModel = Profile.PersistentModel()
      return perisistentModel
    }

    @discardableResult
    func generateLazyProxies() throws -> [AnyProxy.PersistentModel] {
      var models: [AnyProxy.PersistentModel] = []

      let lines = """
        direct = direct,
        reject = reject,
        reject-tinygif = reject-tinygif,
        VMESS = vmess, server-address = https://example.com, port = 443, username = ECE9304F-3987-47F4-9306-89913D31C8F4, tls = true, ws = true, ws-path = ws
        SS = ss, server-address = https://example.com, port = 2222, password-reference = ny]t429'>41U, algo = ChaCha20-Poly1305
        HTTP = http, server-address = http://example.com, port = 6152, authentication-required = true, username = username, password-reference = ny]t429'>41U, force-http-tunneling = true
        HTTPS = https, server-address = https://example.com, port = 443
        SOCKS = socks5, server-address = http://example.com, port = 6153, authentication-required = true, username = username, password-reference = ny]t429'>41U, allow-udp-relay = true
        SOCKS over TLS = socks5-over-tls, server-address = http://example.com, port = 6153, authentication-required = true, username = username, password-reference = ny]t429'>41U, allow-udp-relay = true, tls = true
        """.split(separator: .newlineSequence).shuffled()

      try modelContext?.transaction {
        for parseInput in lines {
          let persistentModel = AnyProxy.PersistentModel()
          let parseOutput = try AnyProxy.FormatStyle().parse(String(parseInput))
          persistentModel.mergeValues(parseOutput)
          modelContext?.insert(persistentModel)
          persistentModel.lazyProfile = self
          models.append(persistentModel)
        }
      }
      return models
    }

    @discardableResult
    func generateLazyProxyGroups(lazyProxies: [AnyProxy.PersistentModel]) throws -> [AnyProxyGroup
      .PersistentModel]
    {
      var models: [AnyProxyGroup.PersistentModel] = []

      try modelContext?.transaction {
        for kind in AnyProxyGroup.Kind.allCases.shuffled() {
          let persistentModel = AnyProxyGroup.PersistentModel()
          persistentModel.name = kind.localizedName
          persistentModel.kind = kind
          var lowerBound = lazyProxies.indices.randomElement() ?? lazyProxies.startIndex
          var upperBound = lazyProxies.indices.randomElement() ?? lazyProxies.endIndex
          lowerBound = min(lowerBound, upperBound)
          upperBound = max(lowerBound, upperBound)
          persistentModel.lazyProxies = Array(lazyProxies[lowerBound...upperBound])
          modelContext?.insert(persistentModel)
          persistentModel.lazyProfile = self
          models.append(persistentModel)
        }
      }
      return models
    }

    @discardableResult
    func generateLazyRules(
      lazyProxies: [AnyProxy.PersistentModel], lazyProxyGroups: [AnyProxyGroup.PersistentModel]
    ) throws -> [AnyForwardingRule.PersistentModel] {
      var models: [AnyForwardingRule.PersistentModel] = []

      let lines = """
        DOMAIN, https://example.com, Foreign
        DOMAIN-KEYWORD, advertisment, Blocked
        DOMAIN-SET, https://ds.example.com, Foreign
        DOMAIN-SUFFIX, apple.com, direct
        RULE-SET, https://rs.example.com, Blocked
        GEOIP, CN, direct
        IP-CIDR, 192.145.212.23/10, Foreign
        FINAL, direct
        """.split(separator: .newlineSequence).shuffled()

      try modelContext?.transaction {
        for parseInput in lines {
          let persistentModel = AnyForwardingRule.PersistentModel()
          let parseOutput = try AnyForwardingRule.FormatStyle().parse(String(parseInput))
          persistentModel.mergeValues(parseOutput)
          let useLazyProxy = [true, false].randomElement() ?? false
          if useLazyProxy {
            persistentModel.lazyProxy = lazyProxies.randomElement()
          } else {
            persistentModel.lazyProxyGroup = lazyProxyGroups.randomElement()
          }
          modelContext?.insert(persistentModel)
          persistentModel.lazyProfile = self
          models.append(persistentModel)
        }
      }
      return models
    }

    @discardableResult
    func generateLazyURLRewrites() throws -> [URLRewrite.PersistentModel] {
      var models: [URLRewrite.PersistentModel] = []
      let lines = """
        found, (?:http://)?swift.org, https://swift.org
        """.split(separator: .newlineSequence).shuffled()

      try modelContext?.transaction {
        for parseInput in lines {
          let persistentModel = URLRewrite.PersistentModel()
          let parseOutput = try URLRewrite.FormatStyle().parse(String(parseInput))
          persistentModel.mergeValues(parseOutput)
          modelContext?.insert(persistentModel)
          persistentModel.lazyProfile = self
          models.append(persistentModel)
        }
      }
      return models
    }

    @discardableResult
    func generateLazyHTTPResponseMocks() throws -> [StubbedHTTPResponse.PersistentModel] {
      var models: [StubbedHTTPResponse.PersistentModel] = []
      let persistentModel = StubbedHTTPResponse.PersistentModel()
      modelContext?.insert(persistentModel)
      persistentModel.lazyProfile = self
      models.append(persistentModel)
      return models
    }

    @discardableResult
    func generateLazyHTTPFieldsRewrites() throws -> [HTTPFieldsRewrite.PersistentModel] {
      var models: [HTTPFieldsRewrite.PersistentModel] = []
      let persistentModel = HTTPFieldsRewrite.PersistentModel()
      modelContext?.insert(persistentModel)
      persistentModel.lazyProfile = self
      models.append(persistentModel)
      return models
    }

    @discardableResult
    func generateLazyDNSMappings() throws -> [DNSMapping.PersistentModel] {
      var models: [DNSMapping.PersistentModel] = []
      let persistentModel = DNSMapping.PersistentModel()
      modelContext?.insert(persistentModel)
      persistentModel.lazyProfile = self
      models.append(persistentModel)
      return models
    }
  }
#endif
