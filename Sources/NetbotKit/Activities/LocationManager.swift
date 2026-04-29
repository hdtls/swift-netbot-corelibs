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

#if canImport(CoreLocation)
  import CoreLocation
  import Logging

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  final public class LocationManager {
    private let locationManager = CLLocationManager()
    private let delegate = __CLLocationManagerDelegate()

    public init() {
      locationManager.delegate = delegate
    }

    public func authorizeLocationServices() throws {
      guard CLLocationManager.locationServicesEnabled() else {
        return
      }
      guard locationManager.authorizationStatus == .notDetermined else {
        return
      }
      locationManager.requestWhenInUseAuthorization()
    }

    public func startUpdatingLocation() {
      locationManager.startUpdatingLocation()
    }

    public func stopUpdatingLocation() {
      locationManager.stopUpdatingLocation()
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension LocationManager {

    final private class __CLLocationManagerDelegate: NSObject, CLLocationManagerDelegate {
      private let logger = Logger(label: "com.apple.CoreLocation")

      func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus == .authorized else {
          return
        }
        manager.startUpdatingLocation()
      }

      func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
      {

      }

      func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        logger.error("\(error)")
      }
    }
  }
#endif
