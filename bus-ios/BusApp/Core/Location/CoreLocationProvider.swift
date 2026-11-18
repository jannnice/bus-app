@preconcurrency import CoreLocation
import Foundation

@MainActor
final class CoreLocationProvider: NSObject, UserLocationProvider, @preconcurrency CLLocationManagerDelegate {
    private let manager: CLLocationManager
    private var continuation: CheckedContinuation<UserLocation, Error>?

    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation() async throws -> UserLocation {
        guard CLLocationManager.locationServicesEnabled() else {
            throw UserLocationError.servicesDisabled
        }

        guard continuation == nil else {
            throw UserLocationError.requestInProgress
        }

        switch manager.authorizationStatus {
        case .denied:
            throw UserLocationError.permissionDenied
        case .restricted:
            throw UserLocationError.permissionRestricted
        case .notDetermined:
            return try await waitForLocation(requestAuthorization: true)
        case .authorizedAlways, .authorizedWhenInUse:
            return try await waitForLocation(requestAuthorization: false)
        @unknown default:
            throw UserLocationError.locationUnavailable
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil else {
            return
        }

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied:
            resume(throwing: UserLocationError.permissionDenied)
        case .restricted:
            resume(throwing: UserLocationError.permissionRestricted)
        case .notDetermined:
            break
        @unknown default:
            resume(throwing: UserLocationError.locationUnavailable)
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else {
            resume(throwing: UserLocationError.locationUnavailable)
            return
        }

        resume(
            returning: UserLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        )
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let locationError = error as? CLError, locationError.code == .denied {
            resume(throwing: UserLocationError.permissionDenied)
        } else {
            resume(throwing: UserLocationError.locationUnavailable)
        }
    }

    private func waitForLocation(requestAuthorization: Bool) async throws -> UserLocation {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation

                if requestAuthorization {
                    manager.requestWhenInUseAuthorization()
                } else {
                    manager.requestLocation()
                }
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.resume(throwing: CancellationError())
            }
        }
    }

    private func resume(returning location: UserLocation) {
        let pendingContinuation = continuation
        continuation = nil
        pendingContinuation?.resume(returning: location)
    }

    private func resume(throwing error: Error) {
        let pendingContinuation = continuation
        continuation = nil
        pendingContinuation?.resume(throwing: error)
    }
}
