//
// See LICENSE.txt for license information
//

#if canImport(SwiftData)
  import SwiftData
  import Testing
  @testable import Netbot
  import _ProfileSupport

  @Suite("V1._AnyForwardingRuleTests", .tags(.swiftData, .schema, .forwardingRule))
  struct AnyRulePersistentModelTests {

    var modelContainer: Any = 0

    init() throws {
      if #available(SwiftStdlib 5.9, *) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let schema: Schema = Schema(versionedSchema: _VersionedSchema.self)
        modelContainer = try ModelContainer(for: schema, configurations: configuration)
      }
    }

    @available(SwiftStdlib 5.9, *)
    @Test func propertyInitialValue() {
      let data = V1._AnyForwardingRule()
      #expect(data.isEnabled)
      #expect(data.kind == .domain)
      #expect(data.value == "")
      #expect(data.comment == "")
      //      #expect(data.foreignKey == "direct")
      #expect(data.notification == .init())
    }

    @available(SwiftStdlib 5.9, *)
    @Test("AnyForwardingRule.init(persistentModel:)")
    func initWithPersistentModel() {
      let modelContext = ModelContext(modelContainer as! ModelContainer)
      let profile = Profile.PersistentModel()
      modelContext.insert(profile)

      let persistentModel = V1._AnyForwardingRule()
      persistentModel.isEnabled = false
      persistentModel.kind = .domainSuffix
      persistentModel.value = "example.com"
      persistentModel.comment = "forwardingRule for example.com"

      var expected = AnyForwardingRule(
        kind: .domainSuffix, value: "example.com", comment: "forwardingRule for example.com")
      expected.isEnabled = false
      expected.foreignKey = "DIRECT"
      #expect(AnyForwardingRule(persistentModel: persistentModel) == expected)

      expected.foreignKey = "DIRECT"
      let proxy = AnyProxy.PersistentModel()
      proxy.name = "DIRECT"
      modelContext.insert(proxy)
      persistentModel.lazyProxy = proxy
      #expect(AnyForwardingRule(persistentModel: persistentModel) == expected)

      persistentModel.lazyProxy = nil

      expected.foreignKey = "DIRECT_GROUP"
      let proxyGroup = AnyProxyGroup.PersistentModel()
      proxyGroup.name = "DIRECT_GROUP"
      modelContext.insert(proxyGroup)
      persistentModel.lazyProxyGroup = proxyGroup
      #expect(AnyForwardingRule(persistentModel: persistentModel) == expected)
    }

    @available(SwiftStdlib 5.9, *)
    @Test func mergeValues() {
      let persistentModel = V1._AnyForwardingRule()
      let forwardingRule = AnyForwardingRule()
      persistentModel.mergeValues(forwardingRule)

      #expect(persistentModel.isEnabled == forwardingRule.isEnabled)
      #expect(persistentModel.kind == forwardingRule.kind)
      #expect(persistentModel.value == forwardingRule.value)
      #expect(persistentModel.comment == forwardingRule.comment)
      #expect(persistentModel.notification == forwardingRule.notification)
    }
  }

  @Suite("V1._AnyForwardingRule.KindTests", .tags(.swiftData, .schema, .forwardingRule))
  struct V1_AnyRuleKindTests {

    @available(SwiftStdlib 5.9, *)
    @Test(
      arguments: zip(
        V1._AnyForwardingRule.Kind.allCases,
        [
          "DOMAIN", "DOMAIN-KEYWORD", "DOMAIN-SUFFIX", "DOMAIN-SET", "RULE-SET", "GEOIP",
          "IP-CIDR", "PROCESS-NAME", "FINAL",
        ]
      ))
    func rawRepresentableConformance(_ kind: V1._AnyForwardingRule.Kind, _ rawValue: String) {
      #expect(V1._AnyForwardingRule.Kind(rawValue: rawValue) == kind)
      #expect(kind.rawValue == rawValue)
      #expect(V1._AnyForwardingRule.Kind(rawValue: "unknown") == nil)
    }

    @available(SwiftStdlib 5.9, *)
    @Test(
      arguments: zip(
        V1._AnyForwardingRule.Kind.allCases,
        [
          "DOMAIN", "DOMAIN-KEYWORD", "DOMAIN-SUFFIX", "DOMAIN-SET", "RULE-SET", "GEOIP",
          "IP-CIDR", "PROCESS-NAME", "FINAL",
        ]
      ))
    func localizedName(_ kind: V1._AnyForwardingRule.Kind, _ localizedName: String) {
      #expect(kind.localizedName == localizedName)
    }
  }

  @Suite("V1._AnyForwardingRule.NotificationTests", .tags(.swiftData, .schema, .forwardingRule))
  struct V1_AnyRuleNotificationTests {

    @available(SwiftStdlib 5.9, *)
    @Test func propertyInitialValue() {
      let notification = V1._AnyForwardingRule.Notification()
      #expect(notification.message == "")
      #expect(!notification.showNotification)
      #expect(notification.timeInterval == 300)
    }

    @available(SwiftStdlib 5.9, *)
    @Test func equatableConformance() async throws {
      let lhs = V1._AnyForwardingRule.Notification()
      let rhs = V1._AnyForwardingRule.Notification()
      #expect(lhs == rhs)
    }
  }
#endif
