//
// See LICENSE.txt for license information
//

#if canImport(Darwin)
  import Foundation
  import Logging
  import UserNotifications

  #if canImport(AppKit)
    import AppKit
  #elseif canImport(UIKit)
    import UIKit
  #endif

  private enum UserNotificationError: Error {
    case denied
  }

  private let logger = Logger(label: "UserNotifications")

  extension UNUserNotificationCenter {

    static var `default`: UNUserNotificationCenter {
      .current()
    }

    func post(_ note: UNNotificationRequest) async {
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
