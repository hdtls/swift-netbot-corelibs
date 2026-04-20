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

#if canImport(os)
  import Foundation
  import Logging
  import os

  /// `LogHandler` is a simple implementation of `LogHandler` for directing
  /// `Logger` output to system log via the factory methods.
  ///
  /// Metadata is merged in the following order:
  /// 1. Metadata set on the log handler itself is used as the base metadata.
  /// 2. The handler's ``metadataProvider`` is invoked, overriding any existing keys.
  /// 3. The per-log-statement metadata is merged, overriding any previously set keys.
  @available(SwiftStdlib 5.3, *)
  public struct OSLogHandler: LogHandler {

    private let logger: os.Logger
    private let label: String

    public var logLevel: Logging.Logger.Level = .info

    private var prettyMetadata: String?
    public var metadata = Logging.Logger.Metadata() {
      didSet {
        self.prettyMetadata = self.prettify(self.metadata)
      }
    }

    public subscript(metadataKey metadataKey: String) -> Logging.Logger.Metadata.Value? {
      get {
        return self.metadata[metadataKey]
      }
      set {
        self.metadata[metadataKey] = newValue
      }
    }

    public init(label: String) {
      let subsystem = Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName
      self.logger = os.Logger(subsystem: subsystem, category: label)
      self.label = label
    }

    public func log(event: LogEvent) {
      let effectiveMetadata = OSLogHandler.prepareMetadata(
        base: self.metadata, provider: self.metadataProvider, explicit: event.metadata)

      let prettyMetadata: String?
      if let effectiveMetadata {
        prettyMetadata = self.prettify(effectiveMetadata)
      } else {
        prettyMetadata = self.prettyMetadata
      }

      var logLevel: OSLogType = .default
      switch event.level {
      case .trace: logLevel = .debug
      case .debug: logLevel = .debug
      case .info: logLevel = .info
      case .notice: logLevel = .info
      case .warning: logLevel = .error
      case .error: logLevel = .error
      case .critical: logLevel = .fault
      }

      let _message = "\(prettyMetadata ?? "") \(event.message)"._trimmingWhitespaces()
      logger.log(level: logLevel, "\(_message, privacy: .public)")
    }

    internal static func prepareMetadata(
      base: Logging.Logger.Metadata, provider: Logging.Logger.MetadataProvider?,
      explicit: Logging.Logger.Metadata?
    ) -> Logging.Logger.Metadata? {
      var metadata = base

      let provided = provider?.get() ?? [:]

      guard !provided.isEmpty || !((explicit ?? [:]).isEmpty) else {
        // all per-log-statement values are empty
        return nil
      }

      if !provided.isEmpty {
        metadata.merge(provided, uniquingKeysWith: { _, provided in provided })
      }

      if let explicit = explicit, !explicit.isEmpty {
        metadata.merge(explicit, uniquingKeysWith: { _, explicit in explicit })
      }

      return metadata
    }

    private func prettify(_ metadata: Logging.Logger.Metadata) -> String? {
      if metadata.isEmpty {
        return nil
      } else {
        return metadata.lazy.sorted(by: { $0.key < $1.key }).map { "\($0)=\($1)" }.joined(
          separator: " ")
      }
    }
  }
#endif
