import Foundation
import XCTest
@testable import BusApp

final class BackendAPIClientTests: XCTestCase {
    override func tearDown() {
        URLProtocolStub.requestHandler = nil
        super.tearDown()
    }

    func testSearchBuildsTheRequestAndDecodesBusStops() async throws {
        URLProtocolStub.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertNil(request.value(forHTTPHeaderField: "X-App-Token"))

            let components = try XCTUnwrap(
                URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)
            )
            XCTAssertEqual(components.path, "/api/v1/bus-stops")
            XCTAssertEqual(components.queryItems?.first { $0.name == "query" }?.value, "grand hotel")
            XCTAssertEqual(components.queryItems?.first { $0.name == "limit" }?.value, "10")

            let data = Data(
                """
                [{
                  "stopCode": "01012",
                  "roadName": "Victoria St",
                  "description": "Hotel Grand Pacific",
                  "latitude": 1.29685,
                  "longitude": 103.853
                }]
                """.utf8
            )
            return (HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!, data)
        }

        let client = makeClient()
        let busStops = try await client.searchBusStops(query: "grand hotel", limit: 10)

        XCTAssertEqual(busStops.map(\.stopCode), ["01012"])
    }

    func testIncludesTheConfiguredAppToken() async throws {
        URLProtocolStub.requestHandler = { request in
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "X-App-Token"),
                "test-app-token"
            )

            let data = Data(
                """
                {
                  "stopCode": "83139",
                  "services": []
                }
                """.utf8
            )
            return (HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!, data)
        }

        _ = try await makeClient(apiToken: "  test-app-token  ").arrivals(for: "83139")
    }

    func testSearchUsesTheBackendErrorMessage() async throws {
        URLProtocolStub.requestHandler = { request in
            let data = Data(
                """
                {
                  "code": "LTA_UNAVAILABLE",
                  "message": "LTA DataMall is temporarily unavailable",
                  "timestamp": "2026-11-17T01:00:00Z",
                  "path": "/api/v1/bus-stops"
                }
                """.utf8
            )
            return (HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 502,
                httpVersion: nil,
                headerFields: nil
            )!, data)
        }

        let client = makeClient()

        do {
            _ = try await client.searchBusStops(query: "grand", limit: 20)
            XCTFail("Expected the request to fail")
        } catch let error as BackendAPIError {
            XCTAssertEqual(
                error,
                .server(
                    statusCode: 502,
                    message: "LTA DataMall is temporarily unavailable"
                )
            )
        }
    }

    func testArrivalsBuildsTheRequestPathAndDecodesTheResponse() async throws {
        URLProtocolStub.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/api/v1/arrivals/83139")
            XCTAssertNil(request.url?.query)

            let data = Data(
                """
                {
                  "stopCode": "83139",
                  "services": [{
                    "serviceNo": "15",
                    "operator": "GAS",
                    "arrivals": []
                  }]
                }
                """.utf8
            )
            return (HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!, data)
        }

        let response = try await makeClient().arrivals(for: "83139")

        XCTAssertEqual(response.stopCode, "83139")
        XCTAssertEqual(response.services.map(\.serviceNo), ["15"])
    }

    func testArrivalsUsesTheBackendErrorMessage() async throws {
        URLProtocolStub.requestHandler = { request in
            let data = Data(
                """
                {
                  "code": "LTA_UNAVAILABLE",
                  "message": "Live arrivals are temporarily unavailable",
                  "timestamp": "2026-11-17T01:00:00Z",
                  "path": "/api/v1/arrivals/83139"
                }
                """.utf8
            )
            return (HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 502,
                httpVersion: nil,
                headerFields: nil
            )!, data)
        }

        do {
            _ = try await makeClient().arrivals(for: "83139")
            XCTFail("Expected the request to fail")
        } catch let error as BackendAPIError {
            XCTAssertEqual(
                error,
                .server(
                    statusCode: 502,
                    message: "Live arrivals are temporarily unavailable"
                )
            )
        }
    }

    func testNearbyStopsBuildsTheRequestAndDecodesResults() async throws {
        URLProtocolStub.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")

            let components = try XCTUnwrap(
                URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)
            )
            XCTAssertEqual(components.path, "/api/v1/bus-stops/nearby")
            XCTAssertEqual(
                components.queryItems?.first { $0.name == "latitude" }?.value,
                "1.2968"
            )
            XCTAssertEqual(
                components.queryItems?.first { $0.name == "longitude" }?.value,
                "103.853"
            )
            XCTAssertEqual(
                components.queryItems?.first { $0.name == "radiusMeters" }?.value,
                "750"
            )
            XCTAssertEqual(
                components.queryItems?.first { $0.name == "limit" }?.value,
                "5"
            )

            let data = Data(
                """
                [{
                  "stopCode": "01012",
                  "roadName": "Victoria St",
                  "description": "Hotel Grand Pacific",
                  "latitude": 1.29685,
                  "longitude": 103.853,
                  "distanceMeters": 85
                }]
                """.utf8
            )
            return (HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!, data)
        }

        let results = try await makeClient().nearbyBusStops(
            latitude: 1.2968,
            longitude: 103.853,
            radiusMeters: 750,
            limit: 5
        )

        XCTAssertEqual(results.map(\.stopCode), ["01012"])
        XCTAssertEqual(results.first?.distanceMeters, 85)
    }

    private func makeClient(apiToken: String? = nil) -> BackendAPIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return BackendAPIClient(
            baseURL: URL(string: "http://localhost:8080")!,
            apiToken: apiToken,
            session: URLSession(configuration: configuration)
        )
    }
}

private final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: BackendAPIError.invalidRequest)
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
