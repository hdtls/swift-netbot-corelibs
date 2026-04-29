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

#if canImport(UserNotifications)
  import Foundation
  import Logging
  import UserNotifications

  #if canImport(AppKit)
    import AppKit
  #elseif canImport(UIKit)
    import UIKit
  #endif

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  private enum UserNotificationError: Error {
    case denied
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  private let logger = Logger(label: "UserNotifications")

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension UNUserNotificationCenter {

    public static var `default`: UNUserNotificationCenter {
      .current()
    }

    public func post(_ note: UNNotificationRequest) async {
      do {
        let notificationCenter = UNUserNotificationCenter.current()
        let settings = await notificationCenter.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional:
          try await notificationCenter.add(note)
        case .notDetermined:
          let notificationCenter = UNUserNotificationCenter.current()
          let options: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional]
          _ = try await notificationCenter.requestAuthorization(options: options)
          await post(note)
        case .denied:
          throw UserNotificationError.denied
        case .ephemeral:
          break
        @unknown default:
          break
        }
      } catch {
        logger.error(
          "perform user notification failure with error: \(error.localizedDescription)"
        )
      }
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension Notification.Name {

    internal static var applicationWillTerminate: Notification.Name {
      #if os(iOS)
        return UIApplication.willTerminateNotification
      #else
        return NSApplication.willTerminateNotification
      #endif
    }
  }
#endif
