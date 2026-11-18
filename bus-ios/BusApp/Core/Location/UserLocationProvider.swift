import Foundation

struct UserLocation: Equatable, Sendable {
    let latitude: Double
    let longitude: Double
}

enum UserLocationError: LocalizedError, Equatable, Sendable {
    case servicesDisabled
    case permissionDenied
    case permissionRestricted
    case locationUnavailable
    case requestInProgress

    var errorDescription: String? {
        switch self {
        case .servicesDisabled:
            "Location Services are turned off on this device."
        case .permissionDenied:
            "Location access is off for Bus App. You can enable it in Settings."
        case .permissionRestricted:
            "Location access is restricted on this device."
        case .locationUnavailable:
            "Your location could not be determined. Please try again."
        case .requestInProgress:
            "A location request is already in progress."
        }
    }
}

@MainActor
protocol UserLocationProvider {
    func requestLocation() async throws -> UserLocation
}
