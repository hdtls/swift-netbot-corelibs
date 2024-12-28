//
// See LICENSE.txt for license information
//

#if canImport(SwiftData)
  import SwiftData
  import Testing

  @testable import NetbotData

  @Suite("V1._DNSMappingTests", .tags(.swiftData, .schema, .dnsMapping))
  struct DNSMappingPersistentModelTests {

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
      let data = V1._DNSMapping()
      #expect(data.kind == .mapping)
      #expect(data.isEnabled)
      #expect(data.domainName == "")
      #expect(data.value == "")
      #expect(data.note == "")
    }

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test("DNSMapping.init(persistentModel:)")
    func initWithPersistentModel() {
      let persistentModel = V1._DNSMapping()
      let data = DNSMapping(persistentModel: persistentModel)

      #expect(data.kind == persistentModel.kind)
      #expect(data.domainName == persistentModel.domainName)
      #expect(data.value == persistentModel.value)
      #expect(data.note == persistentModel.note)
    }

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test func mergeValues() {
      let persistentModel = V1._DNSMapping()
      let data = DNSMapping()
      persistentModel.mergeValues(data)

      #expect(data.kind == persistentModel.kind)
      #expect(data.domainName == persistentModel.domainName)
      #expect(data.value == persistentModel.value)
      #expect(data.note == persistentModel.note)
    }
  }

  @Suite("V1._DNSMapping.KindTests", .tags(.swiftData, .schema, .dnsMapping))
  struct V1_DNSMappingKindTests {

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test(arguments: zip(V1._DNSMapping.Kind.allCases, [0, 1, 2]))
    func rawRepresentableConformance(_ kind: V1._DNSMapping.Kind, _ rawValue: Int) {
      #expect(V1._DNSMapping.Kind(rawValue: rawValue) == kind)
      #expect(kind.rawValue == rawValue)
      #expect(V1._DNSMapping.Kind(rawValue: 9) == nil)
    }

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test func caseIterableConformance() {
      #expect(V1._DNSMapping.Kind.allCases == [.mapping, .cname, .dns])
    }
  }
#endif
