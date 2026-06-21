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

import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
@_spi(XCTestFailureLocation) import SwiftSyntaxMacrosGenericTestSupport
import Testing

// Re-export the spec types from `SwiftSyntaxMacrosGenericTestSupport`.
typealias NoteSpec = SwiftSyntaxMacrosGenericTestSupport.NoteSpec
typealias FixItSpec = SwiftSyntaxMacrosGenericTestSupport.FixItSpec
typealias DiagnosticSpec = SwiftSyntaxMacrosGenericTestSupport.DiagnosticSpec

/// Assert that expanding the given macros in the original source produces
/// the given expanded source code.
///
/// - Parameters:
///   - originalSource: The original source code, which is expected to contain
///     macros in various places (e.g., `#stringify(x + y)`).
///   - expectedExpandedSource: The source code that we expect to see after
///     performing macro expansion on the original source.
///   - diagnostics: The diagnostics when expanding any macro
///   - macros: The macros that should be expanded, provided as a dictionary
///     mapping macro names (e.g., `"stringify"`) to implementation types
///     (e.g., `StringifyMacro.self`).
///   - testModuleName: The name of the test module to use.
///   - testFileName: The name of the test file name to use.
///   - indentationWidth: The indentation width used in the expansion.
///
/// - SeeAlso: ``assertMacroExpansion(_:expandedSource:diagnostics:macroSpecs:applyFixIts:fixedSource:testModuleName:testFileName:indentationWidth:file:line:)``
///   to also specify the list of conformances passed to the macro expansion.
func assertMacroExpansion(
  _ originalSource: String,
  expandedSource expectedExpandedSource: String,
  diagnostics: [DiagnosticSpec] = [],
  macros: [String: Macro.Type],
  applyFixIts: [String]? = nil,
  fixedSource expectedFixedSource: String? = nil,
  testModuleName: String = "TestModule",
  testFileName: String = "test.swift",
  indentationWidth: Trivia = .spaces(2),
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) {
  let specs = macros.mapValues { MacroSpec(type: $0) }
  assertMacroExpansion(
    originalSource,
    expandedSource: expectedExpandedSource,
    diagnostics: diagnostics,
    macroSpecs: specs,
    applyFixIts: applyFixIts,
    fixedSource: expectedFixedSource,
    testModuleName: testModuleName,
    testFileName: testFileName,
    indentationWidth: indentationWidth,
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}

/// Assert that expanding the given macros in the original source produces
/// the given expanded source code.
///
/// - Parameters:
///   - originalSource: The original source code, which is expected to contain
///     macros in various places (e.g., `#stringify(x + y)`).
///   - expectedExpandedSource: The source code that we expect to see after
///     performing macro expansion on the original source.
///   - diagnostics: The diagnostics when expanding any macro
///   - macroSpecs: The macros that should be expanded, provided as a dictionary
///     mapping macro names (e.g., `"CodableMacro"`) to specification with macro type
///     (e.g., `CodableMacro.self`) and a list of conformances macro provides
///     (e.g., `["Decodable", "Encodable"]`).
///   - applyFixIts: If specified, filters the Fix-Its that are applied to generate `fixedSource` to only those whose message occurs in this array. If `nil`, all Fix-Its from the diagnostics are applied.
///   - fixedSource: If specified, asserts that the source code after applying Fix-Its matches this string.
///   - testModuleName: The name of the test module to use.
///   - testFileName: The name of the test file name to use.
///   - indentationWidth: The indentation width used in the expansion.
func assertMacroExpansion(
  _ originalSource: String,
  expandedSource expectedExpandedSource: String,
  diagnostics: [DiagnosticSpec] = [],
  macroSpecs: [String: MacroSpec],
  applyFixIts: [String]? = nil,
  fixedSource expectedFixedSource: String? = nil,
  testModuleName: String = "TestModule",
  testFileName: String = "test.swift",
  indentationWidth: Trivia = .spaces(2),
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) {
  SwiftSyntaxMacrosGenericTestSupport.assertMacroExpansion(
    originalSource,
    expandedSource: expectedExpandedSource,
    diagnostics: diagnostics,
    macroSpecs: macroSpecs,
    applyFixIts: applyFixIts,
    fixedSource: expectedFixedSource,
    testModuleName: testModuleName,
    testFileName: testFileName,
    indentationWidth: indentationWidth,
    failureHandler: {
      Issue.record(
        SwiftSyntaxMacros.MacroExpansionErrorMessage($0.message),
        "\($0.message)",
        sourceLocation: .init(
          fileID: $0.location.fileID,
          filePath: $0.location.filePath,
          line: $0.location.line,
          column: $0.location.column
        )
      )
    },
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}
