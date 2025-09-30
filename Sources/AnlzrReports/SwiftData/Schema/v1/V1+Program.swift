//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2024 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if swift(>=6.3) || canImport(Darwin)
  import Observation

  #if canImport(FoundationEssentials)
    import FoundationEssentials
  #else
    import Foundation
  #endif

  #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
    import SwiftData
  #endif

  @available(SwiftStdlib 5.9, *)
  extension V1 {

    #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
      @available(SwiftStdlib 5.9, *)
      @Model final public class _Program {

        @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, *)
        #Unique<_Program>([\.localizedName])

        /// Indicates the name of the program.
        /// This is dependent on the current localization of the referenced program, and is suitable for presentation to the user.
        @Attribute(.unique)
        public var localizedName: String = "Unknown"

        /// Indicates the URL to the application's bundle, or nil if the application does not have a bundle.
        public var bundleURL: URL?

        /// Indicates the URL to the application's executable.
        public var executableURL: URL?

        /// Indicates the icon TIFF representation data of the application.
        @Attribute(.externalStorage)
        public var iconTIFFRepresentation: Data?

        @Relationship(inverse: \_ProcessReport.program)
        public var processReports: [_ProcessReport] = []

        @Relationship(inverse: \_DataTransferReport.program)
        public var dataTransferReport: _DataTransferReport?

        public init() {}
      }
    #else
      @Observable final public class _Program {

        /// Indicates the name of the program.
        /// This is dependent on the current localization of the referenced program, and is suitable for presentation to the user.
        public var localizedName: String = "Unknown"

        /// Indicates the URL to the application's bundle, or nil if the application does not have a bundle.
        public var bundleURL: URL?

        /// Indicates the URL to the application's executable.
        public var executableURL: URL?

        /// Indicates the icon TIFF representation data of the application.
        public var iconTIFFRepresentation: Data?

        public var processReports: [_ProcessReport] = []

        public var dataTransferReport: _DataTransferReport?

        public init() {}
      }
    #endif
  }

  #if !(canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA)
    @available(SwiftStdlib 5.9, *)
    extension V1._Program: Identifiable {
      public var id: String { persistentModelID }

      public var persistentModelID: String { localizedName }
    }
  #endif

  @available(SwiftStdlib 5.9, *)
  extension V1._Program {

    /// Merge new values from data transfer object.
    /// - Parameter data: New `Request` to merge.
    public func mergeValues(_ data: Program) {
      #if swift(>=6.2) && !(canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA)
        localizedName = data.localizedName
        bundleURL = data.bundleURL
        executableURL = data.executableURL
        iconTIFFRepresentation = data.iconTIFFRepresentation
      #else
        if localizedName != data.localizedName {
          localizedName = data.localizedName
        }
        if bundleURL != data.bundleURL {
          bundleURL = data.bundleURL
        }
        if executableURL != data.executableURL {
          executableURL = data.executableURL
        }
        if iconTIFFRepresentation != data.iconTIFFRepresentation {
          iconTIFFRepresentation = data.iconTIFFRepresentation
        }
      #endif
    }
  }
#endif
