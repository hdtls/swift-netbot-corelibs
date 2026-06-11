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

import Testing

@testable import NetbotLiteData

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite struct ProgramTests {

  @available(SwiftStdlib 6.0, *)
  @Test func defaultProperties() {
    let program = Program()
    #expect(program.localizedName == "")
    #expect(program.bundleURL == nil)
    #expect(program.executableURL == nil)
    #expect(program.iconTIFFRepresentation == nil)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func hashableConformance() {
    let program1 = Program()
    let program2 = Program()
    let program3 = Program(localizedName: "ssh")
    #expect(program1 == program2)
    #expect(program1 != program3)

    let programs = Set([program1, program2, program3])
    #expect(programs == [program1, program3])
  }

  @available(SwiftStdlib 6.0, *)
  @Test func codableConformance() {
    let program = Program()

    #expect(throws: Never.self) {
      let data = try JSONEncoder().encode(program)
      let decoded = try JSONDecoder().decode(Program.self, from: data)
      #expect(decoded == program)
    }
  }

  @available(SwiftStdlib 6.0, *)
  @Test func identifiableConformance() {
    let program = Program(localizedName: "ssh")
    #expect(program.id == "ssh")
  }

  @available(SwiftStdlib 6.0, *)
  @Test func initFromPersistentModel() async throws {
    let bundleURL = URL(string: "file:///Applications/FakeApp.app")
    let execURL = URL(string: "file:///Applications/FakeApp.app/Contents/MacOS/FakeApp")
    let iconData = Data("icondata".utf8)
    let persistent = V1._Program()
    persistent.localizedName = "FakeApp"
    persistent.bundleURL = bundleURL
    persistent.executableURL = execURL
    persistent.iconTIFFRepresentation = iconData

    let program = Program(persistentModel: persistent)
    #expect(program.localizedName == "FakeApp")
    #expect(program.bundleURL == bundleURL)
    #expect(program.executableURL == execURL)
    #expect(program.iconTIFFRepresentation == iconData)
  }
}
