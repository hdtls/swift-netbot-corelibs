//
// See LICENSE.txt for license information
//

import Testing

@testable import _ProfileSupport

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite(.tags(.urlRewrite, .formatting))
struct URLRewriteFormatStyleTests {

  @Test(arguments: [
    URLRewrite.FormatStyle(),
    URLRewrite.FormatStyle.urlRewrite,
  ])
  func format(_ formatter: URLRewrite.FormatStyle) throws {
    var urlRewrite = URLRewrite()
    urlRewrite.type = .found
    urlRewrite.pattern = "(?:http://)?swift.org"
    urlRewrite.destination = "https://swift.org"

    let expected = "found, (?:http://)?swift.org, https://swift.org"
    #expect(formatter.format(urlRewrite) == expected)
    #expect(urlRewrite.formatted() == expected)
    #expect(urlRewrite.formatted(formatter) == expected)
  }

  @Test(arguments: [
    URLRewrite.FormatStyle(),
    URLRewrite.FormatStyle().parseStrategy,
    URLRewrite.FormatStyle.urlRewrite,
  ])
  func parse(_ parser: URLRewrite.FormatStyle) throws {
    let parseInput = "found, (?:http://)?swift.org, https://swift.org"
    let parseOutput = try parser.parse(parseInput)

    #expect(parseOutput.isEnabled)
    #expect(parseOutput.type == .found)
    #expect(parseOutput.pattern == "(?:http://)?swift.org")
    #expect(parseOutput.destination == "https://swift.org")
  }

  @Test(arguments: [
    "abc, (?:http://)?swift.org, https://swift.org",
    "found, (?:http://)?swift.org",
  ])
  func parseFromInvalidString(_ parseInput: String) throws {
    #expect(throws: CocoaError.self) {
      try URLRewrite.FormatStyle().parse(parseInput)
    }
  }

  @Test func formatStyleConformance() {
    var urlRewrite = URLRewrite()
    urlRewrite.type = .found
    urlRewrite.pattern = "(?:http://)?swift.org"
    urlRewrite.destination = "https://swift.org"

    #expect(urlRewrite.formatted(.urlRewrite) == "found, (?:http://)?swift.org, https://swift.org")
  }

  @Test func parseStrategyConformance() {
    #expect(throws: Never.self) {
      try URLRewrite("found, (?:http://)?swift.org, https://swift.org", strategy: .urlRewrite)
    }
  }
}
