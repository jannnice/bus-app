import Foundation

struct BackendAPIClient: BusStopAPIClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    init(
        baseURL: URL,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func searchBusStops(query: String, limit: Int = 20) async throws -> [BusStop] {
        guard var components = URLComponents(
            url: baseURL.appending(path: "/api/v1/bus-stops"),
            resolvingAgainstBaseURL: false
        ) else {
            throw BackendAPIError.invalidRequest
        }

        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url else {
            throw BackendAPIError.invalidRequest
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendAPIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let apiError = try? decoder.decode(APIErrorResponse.self, from: data)
            throw BackendAPIError.server(
                statusCode: httpResponse.statusCode,
                message: apiError?.message ?? "The backend returned an error."
            )
        }

        do {
            return try decoder.decode([BusStop].self, from: data)
        } catch {
            throw BackendAPIError.decodingFailed
        }
    }
}
