import Foundation

enum BusWidgetLink: Equatable {
    case favorites
    case arrivals(String)

    init?(url: URL) {
        guard let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              parts.scheme == "busapp", parts.user == nil, parts.password == nil,
              parts.port == nil, parts.query == nil, parts.fragment == nil else { return nil }

        switch (parts.host, parts.percentEncodedPath) {
        case ("favorites", ""):
            self = .favorites
        case ("arrivals", let path) where path.first == "/" && Self.isStopCode(String(path.dropFirst())):
            self = .arrivals(String(path.dropFirst()))
        default:
            return nil
        }
    }

    var url: URL? {
        switch self {
        case .favorites: URL(string: "busapp://favorites")
        case .arrivals(let code): Self.isStopCode(code) ? URL(string: "busapp://arrivals/\(code)") : nil
        }
    }

    private static func isStopCode(_ code: String) -> Bool {
        code.utf8.count == 5 && code.utf8.allSatisfy { (48...57).contains($0) }
    }
}
