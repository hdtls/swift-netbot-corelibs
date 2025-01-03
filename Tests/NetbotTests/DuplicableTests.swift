//
// See LICENSE.txt for license information
//

import Testing

@testable import Netbot

@Suite struct DuplicableTests {

  class File: Duplicable {
    var name: String

    required init(named: String) {
      self.name = named
    }

    func copy() -> Self {
      return .init(named: name)
    }
  }

  @Test func duplicate() {
    let file = File(named: "info")
    var copyed = file.copy()
    #expect(file.name == copyed.name)
    #expect(file !== copyed)

    let files = [file]
    copyed = files.duplicate(file, name: \.name)
    #expect(copyed.name == "info copy")

    #expect(["info"].duplicate("info") == "info copy")
  }

  @Test func duplicateInAnArrayThatAlreadyContainsACopy() {
    let file = File(named: "info")

    var files = [file]
    files.append(files.duplicate(file, name: \.name))
    let copyed = files.duplicate(file, name: \.name)
    #expect(copyed.name == "info copy 1")

    #expect(["info", "info copy"].duplicate("info") == "info copy 1")
  }

  @Test func duplicateInAnArrayThatContainsMultipleCopys() {
    let file = File(named: "info")

    var files = [file]
    files.append(files.duplicate(file, name: \.name))
    files.append(files.duplicate(file, name: \.name))
    files.append(files.duplicate(file, name: \.name))
    files.append(files.duplicate(file, name: \.name))
    files.append(files.duplicate(file, name: \.name))
    #expect(files.last?.name == "info copy 4")

    files.remove(at: 1)
    files.append(files.duplicate(file, name: \.name))
    #expect(files.last?.name == "info copy")

    files.remove(at: 2)
    files.append(files.duplicate(file, name: \.name))
    #expect(files.last?.name == "info copy 2")

    #expect(["info", "info copy", "info copy 3"].duplicate("info") == "info copy 1")
  }
}
