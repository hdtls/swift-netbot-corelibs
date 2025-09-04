//
// See LICENSE.txt for license information
//

#if canImport(CoreLocation)
  import CoreLocation
  import Logging

  @available(SwiftStdlib 5.3, *)
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

  @available(SwiftStdlib 5.3, *)
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
