//
// See LICENSE.txt for license information
//

//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2021 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

private import CNIOBoringSSL

/// Wraps a single error from BoringSSL.
public struct BoringSSLInternalError: Equatable, CustomStringConvertible, Sendable {
  private enum Backing: Hashable {
    case boringSSLErrorInfo(UInt32, String, UInt)
  }

  private var backing: Backing

  private var errorMessage: String? {
    switch self.backing {
    case .boringSSLErrorInfo(let errorCode, let filepath, let line):
      // TODO(cory): This should become non-optional in the future, as it always succeeds.
      var scratchBuffer = [CChar](repeating: 0, count: 512)
      return scratchBuffer.withUnsafeMutableBufferPointer { pointer in
        CNIOBoringSSL_ERR_error_string_n(errorCode, pointer.baseAddress!, pointer.count)
        let errorString = String(cString: pointer.baseAddress!)
        return "\(errorString) at \(filepath):\(line)"
      }
    }
  }

  private var errorCode: String {
    switch self.backing {
    case .boringSSLErrorInfo(let code, _, _):
      return String(code, radix: 10)
    }
  }

  public var description: String {
    "Error: \(errorCode) \(errorMessage ?? "")"
  }

  init(errorCode: UInt32, filename: String, line: UInt) {
    self.backing = .boringSSLErrorInfo(errorCode, filename, line)
  }
}

/// A representation of BoringSSL's internal error stack: a list of BoringSSL errors.
public typealias NIOBoringSSLErrorStack = [BoringSSLInternalError]

/// An enum that wraps individual BoringSSL errors directly.
public enum BoringSSLError: Error {
  case unknownError(NIOBoringSSLErrorStack)
}

extension BoringSSLError: Equatable {}

extension BoringSSLError {
  static func buildErrorStack() -> NIOBoringSSLErrorStack {
    var errorStack = NIOBoringSSLErrorStack()

    while true {
      var file: UnsafePointer<CChar>? = nil
      var line: CInt = 0
      let errorCode = CNIOBoringSSL_ERR_get_error_line(&file, &line)
      if errorCode == 0 { break }
      let fileAsString = String(cString: file!)
      errorStack.append(
        BoringSSLInternalError(errorCode: errorCode, filename: fileAsString, line: UInt(line)))
    }

    return errorStack
  }
}
