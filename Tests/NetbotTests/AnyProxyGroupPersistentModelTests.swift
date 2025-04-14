//
// See LICENSE.txt for license information
//

#if canImport(SwiftData)
  import SwiftData
  import Testing

  @testable import Netbot
  import _ResourceProcessing

  @Suite("V1._AnyProxyGroupTests", .tags(.swiftData, .schema, .proxyGroup))
  struct V1_AnyProxyGroupTests {

    var modelContainer: Any = 0

    init() throws {
      if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let schema: Schema = Schema(versionedSchema: _VersionedSchema.self)
        modelContainer = try ModelContainer(for: schema, configurations: configuration)
      }
    }

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test func propertyInitialValue() {
      let persistentModel = V1._AnyProxyGroup()
      #expect(persistentModel.kind == .select)
      #expect(persistentModel.resource == .init())
    }

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test("AnyProxyGroup.init(persistentModel:)")
    func initWithPersistentModel() {
      let persistentModel = V1._AnyProxyGroup()
      let group = AnyProxyGroup(persistentModel: persistentModel)

      #expect(group.name == persistentModel.name)
      #expect(group.kind == persistentModel.kind)
      #expect(group.resource == persistentModel.resource)
      #expect(group.measurement == persistentModel.measurement)
      #expect(group.creationDate == persistentModel.creationDate)
    }

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test func mergeValues() {
      let persistentModel = V1._AnyProxyGroup()
      let group = AnyProxyGroup()
      persistentModel.mergeValues(group)

      #expect(persistentModel.name == group.name)
      #expect(persistentModel.kind == group.kind)
      #expect(persistentModel.resource == group.resource)
      #expect(persistentModel.measurement == group.measurement)
      #expect(persistentModel.creationDate == group.creationDate)
    }
  }

  @Suite("V1._AnyProxyGroup.KindTests", .tags(.swiftData, .schema, .proxyGroup))
  struct V1_AnyProxyGroupKindTests {

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test(
      arguments: zip(
        V1._AnyProxyGroup.Kind.allCases,
        [
          "Select Group", "Auto URL Test Group", "Fallback Group", "SSID Group",
          "Load Balance Group",
        ]
      )
    )
    func localizedName(_ kind: V1._AnyProxyGroup.Kind, _ localizedName: String) {
      #expect(kind.localizedName == localizedName)
    }

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test(
      arguments: zip(
        V1._AnyProxyGroup.Kind.allCases,
        [
          "Select which policy will be used on user interface.",
          "Automatically select which policy will be used by benchmarking the latency to a URL.",
          "Automatically select an available policy by priority. The availability is tested by accessing a URL like the auto URL test group.",
          "Select which policy will be used according to the current Wi-Fi SSID.",
          "Use a random sub-policy for every connections.",
        ]
      )
    )
    func localizedDescription(_ kind: V1._AnyProxyGroup.Kind, _ description: String) {
      #expect(kind.localizedDescription == description)
    }

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test func caseIterableConformance() {
      #expect(
        V1._AnyProxyGroup.Kind.allCases == [.select, .urlTest, .fallback, .ssid, .loadBalance])
    }

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test(
      arguments: zip(
        V1._AnyProxyGroup.Kind.allCases,
        ["select", "url-test", "fallback", "ssid", "load-balance"]
      )
    )
    func rawRepresentableConformance(_ kind: V1._AnyProxyGroup.Kind, _ rawValue: String) {
      #expect(kind.rawValue == rawValue)
      #expect(V1._AnyProxyGroup.Kind(rawValue: rawValue) == kind)
      #expect(V1._AnyProxyGroup.Kind(rawValue: "unknown") == nil)
    }
  }

  @Suite("V1_AnyProxyGroup.MeasurementTests", .tags(.swiftData, .schema, .proxyGroup))
  struct V1_AnyProxyGroupMeasurementTests {

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test func propertyInitialValue() {
      let transactionMetrics = TransactionMetrics()
      let measurement = V1._AnyProxyGroup.Measurement(transactionMetrics: transactionMetrics)
      #expect(measurement.url == nil)
      #expect(measurement.transactionMetricsExpiryInterval == 600.0)
      #expect(measurement.timeout == 5.0)
      #expect(measurement.tolerance == 100)
      #expect(measurement.transactionMetrics == transactionMetrics)
    }
  }

  @Suite("V1._AnyProxyGroup.ResourceTests", .tags(.swiftData, .schema, .proxyGroup))
  struct V1_AnyProxyGroupResourceTests {

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test func propertyInitialValue() {
      let resource = V1._AnyProxyGroup.Resource()
      #expect(resource.source == .cache)
      #expect(resource.externalProxiesURL == nil)
      #expect(resource.externalProxiesAutoUpdateTimeInterval == 86400)
    }
  }

  @Suite("V1._AnyProxyGroup.Resource.SourceTests", .tags(.swiftData, .schema, .proxyGroup))
  struct V1_AnyProxyGroupResourceSourceTests {

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test func caseIterableConformance() {
      #expect(V1._AnyProxyGroup.Resource.Source.allCases == [.cache, .query])
    }
  }
#endif
