import Foundation

enum AppConfiguration {
    static var backendBaseURL: URL {
        guard let url = configuredBackendURL else {
            preconditionFailure("BackendBaseURL is missing or invalid in Info.plist")
        }
        return url
    }

    static var configuredBackendURL: URL? {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "BackendBaseURL") as? String,
            let url = URL(string: value),
            let scheme = url.scheme, ["http", "https"].contains(scheme), url.host != nil
        else {
            return nil
        }

        return url
    }

    static var backendAPIToken: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "BackendAPIToken") as? String else {
            return nil
        }

        let token = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return token.isEmpty ? nil : token
    }
}
