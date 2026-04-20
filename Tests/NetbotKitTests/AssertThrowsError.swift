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

// swift-format-ignore-file

import XCTest

/// Asserts that an asynchronous expression throws an error.
/// (Intended to function as a drop-in asynchronous version of `XCTAssertThrowsError`.)
///
/// Example usage:
///
///     await XCTAssertThrowsError(
///         try await sut.function()
///     ) { error in
///         XCTAssertEqual(error as? MyError, MyError.specificError)
///     }
///
/// - Parameters:
///   - expression: An asynchronous expression that can throw an error.
///   - message: An optional description of a failure.
///   - file: The file where the failure occurs.
///     The default is the filename of the test case where you call this function.
///   - line: The line number where the failure occurs.
///     The default is the line number where you call this function.
///   - errorHandler: An optional handler for errors that expression throws.
func XCTAssertThrowsError<T>(
  _ expression: @autoclosure () async throws -> T,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #filePath,
  line: UInt = #line,
  _ errorHandler: (_ error: any Error) -> Void = { _ in }
) async {
  do {
    _ = try await expression()
    // expected error to be thrown, but it was not
    let customMessage = message()
    if customMessage.isEmpty {
      XCTFail("Asynchronous call did not throw an error.", file: file, line: line)
    } else {
      XCTFail(customMessage, file: file, line: line)
    }
  } catch {
    errorHandler(error)
  }
}

func XCTAssertNoThrow<T>(
  _ expression: @autoclosure () async throws -> T,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #filePath,
  line: UInt = #line
) async {
  do {
    _ = try await expression()
  } catch {
    // expected error to be thrown, but it was not
    let customMessage = message()
    if customMessage.isEmpty {
      XCTFail("Asynchronous call did throw an error.", file: file, line: line)
    } else {
      XCTFail(customMessage, file: file, line: line)
    }
  }
}
