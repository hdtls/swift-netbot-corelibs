//
// See LICENSE.txt for license information
//

#if canImport(SwiftData)
  import SwiftData
  import Testing

  @testable import Netbot
  import _ResourceProcessing

  @Suite("v1.HTTPFieldsRewriteTests", .tags(.httpFieldsRewrite))
  struct V1_HTTPFieldsRewriteTests {

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
    @Test func propertyInitialValue() async throws {
      let data = V1._HTTPFieldsRewrite()
      #expect(data.isEnabled)
      #expect(data.direction == .request)
      #expect(data.pattern == "")
      #expect(data.action == .add)
      #expect(data.name == "")
      #expect(data.value == "")
      #expect(data.replacement == "")
    }
  }

  @Suite("v1.HTTPFieldsRewrite.DirectionTests", .tags(.httpFieldsRewrite))
  struct V1_HTTPFieldsRewriteHDirectionTests {

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test(
      arguments: zip(
        V1._HTTPFieldsRewrite.Direction.allCases, ["request", "response"]
      )
    )
    func rawRepresentableConformance(_ type: V1._HTTPFieldsRewrite.Direction, _ rawValue: String) {
      #expect(V1._HTTPFieldsRewrite.Direction(rawValue: rawValue) == type)
      #expect(type.rawValue == rawValue)
      #expect(V1._HTTPFieldsRewrite.Direction(rawValue: "unknown") == nil)
    }

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test func caseIterableConformance() {
      #expect(V1._HTTPFieldsRewrite.Direction.allCases == [.request, .response])
    }
  }

  @Suite("v1.HTTPFieldsRewrite.Action", .tags(.urlRewrite))
  struct V1_HTTPFieldsRewriteActionTests {

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test(
      arguments: zip(
        V1._HTTPFieldsRewrite.Action.allCases, ["add", "remove", "replace"]
      )
    )
    func rawRepresentableConformance(_ type: V1._HTTPFieldsRewrite.Action, _ rawValue: String) {
      #expect(V1._HTTPFieldsRewrite.Action(rawValue: rawValue) == type)
      #expect(type.rawValue == rawValue)
      #expect(V1._HTTPFieldsRewrite.Action(rawValue: "unknown") == nil)
    }

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test func caseIterableConformance() {
      #expect(V1._HTTPFieldsRewrite.Action.allCases == [.add, .remove, .replace])
    }
  }
#endif
