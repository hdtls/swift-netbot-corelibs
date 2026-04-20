// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

import Testing

@testable import NetbotLiteData

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
  import SwiftData
#endif

@Suite struct V1_ProgramTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValues() async throws {
    let report = V1._Program()
    #expect(report.localizedName == "Unknown")
    #expect(report.bundleURL == nil)
    #expect(report.executableURL == nil)
    #expect(report.iconTIFFRepresentation == nil)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func programIdentifiable() async throws {
    #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
      let program = Program()
      #expect(program.id == program.persistentModelID)

      let programPersistentModel = V1._Program()
      #expect(programPersistentModel.id == programPersistentModel.persistentModelID)
    #else
      let program = Program(localizedName: "AnotherApp")
      #expect(program.persistentModelID == "AnotherApp")
      #expect(program.id == program.persistentModelID)

      let programPersistentModel = V1._Program()
      programPersistentModel.localizedName = "AnotherApp"
      #expect(programPersistentModel.persistentModelID == "AnotherApp")
      #expect(programPersistentModel.id == programPersistentModel.persistentModelID)
    #endif
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func mergeValues() async throws {
    let oldIcon = Data("oldicon".utf8)
    let persistent = V1._Program()
    persistent.localizedName = "OldApp"
    persistent.bundleURL = URL(string: "file:///old.bundle")
    persistent.executableURL = URL(string: "file:///old.exec")
    persistent.iconTIFFRepresentation = oldIcon

    let newIcon = Data("newicon".utf8)
    let program = Program(
      localizedName: "NewApp", bundleURL: URL(string: "file:///new.bundle"),
      executableURL: URL(string: "file:///new.exec"), iconTIFFRepresentation: newIcon)

    persistent.mergeValues(program)

    #expect(persistent.localizedName == "NewApp")
    #expect(persistent.bundleURL == URL(string: "file:///new.bundle"))
    #expect(persistent.executableURL == URL(string: "file:///new.exec"))
    #expect(persistent.iconTIFFRepresentation == newIcon)
  }
}
