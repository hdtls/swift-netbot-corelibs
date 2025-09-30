//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if swift(>=6.3) || canImport(Darwin)
  import Testing

  @testable import AnlzrReports

  #if canImport(FoundationEssentials)
    import FoundationEssentials
  #else
    import Foundation
  #endif

  @Suite struct ProgramTests {

    @available(SwiftStdlib 5.9, *)
    @Test func programInitFromPersistentModel() async throws {
      let bundleURL = URL(string: "file:///Applications/FakeApp.app")
      let execURL = URL(string: "file:///Applications/FakeApp.app/Contents/MacOS/FakeApp")
      let iconData = "icondata".data(using: .utf8)
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
#endif
