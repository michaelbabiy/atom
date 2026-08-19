// AtomNetworking
//
// Copyright (c) 2025 Alaska Airlines
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

@testable import AtomNetworking
import Foundation
import XCTest

// MARK: - ServiceActorRequestKeyTests

final class ServiceActorRequestKeyTests: XCTestCase {
    func testTheKeyCarriesTheMethodAndTheFullyResolvedURL() async throws {
        // Given
        let serviceConfiguration: ServiceConfiguration = .init()
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration, session: StubURLProtocol.session)
        let endpoint: DeduplicationEndpoint = .init(queryItems: [QueryItem(name: "flight", value: "1")])

        // When
        let key: ServiceActor.RequestKey = try await serviceActor.requestKey(for: endpoint)

        // Then
        XCTAssertEqual(key.method, "GET")
        XCTAssertEqual(key.url, "https://api.alaskaair.com/path?flight=1")
    }

    func testIdenticalRequestsProduceEqualKeys() async throws {
        // Given
        let serviceConfiguration: ServiceConfiguration = .init()
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration, session: StubURLProtocol.session)
        let first: DeduplicationEndpoint = .init(queryItems: [QueryItem(name: "flight", value: "1")])
        let second: DeduplicationEndpoint = .init(queryItems: [QueryItem(name: "flight", value: "1")])

        // When
        let firstKey: ServiceActor.RequestKey = try await serviceActor.requestKey(for: first)
        let secondKey: ServiceActor.RequestKey = try await serviceActor.requestKey(for: second)

        // Then
        XCTAssertEqual(firstKey, secondKey)
    }

    func testDifferingHeaderItemsProduceTheSameKey() async throws {
        // Given
        let serviceConfiguration: ServiceConfiguration = .init()
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration, session: StubURLProtocol.session)
        let first: DeduplicationEndpoint = .init(headerItems: [HeaderItem(name: "Authorization", value: "Bearer first")])
        let second: DeduplicationEndpoint = .init(headerItems: [HeaderItem(name: "Authorization", value: "Bearer second")])

        // When
        let firstKey: ServiceActor.RequestKey = try await serviceActor.requestKey(for: first)
        let secondKey: ServiceActor.RequestKey = try await serviceActor.requestKey(for: second)

        // Then
        XCTAssertEqual(firstKey, secondKey)
    }

    func testDifferingQueryItemsProduceDifferentKeys() async throws {
        // Given
        let serviceConfiguration: ServiceConfiguration = .init()
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration, session: StubURLProtocol.session)
        let first: DeduplicationEndpoint = .init(queryItems: [QueryItem(name: "flight", value: "1")])
        let second: DeduplicationEndpoint = .init(queryItems: [QueryItem(name: "flight", value: "2")])

        // When
        let firstKey: ServiceActor.RequestKey = try await serviceActor.requestKey(for: first)
        let secondKey: ServiceActor.RequestKey = try await serviceActor.requestKey(for: second)

        // Then
        XCTAssertNotEqual(firstKey, secondKey)
        XCTAssertEqual(firstKey.method, secondKey.method)
    }

    func testDifferingMethodsProduceDifferentKeys() async throws {
        // Given
        let serviceConfiguration: ServiceConfiguration = .init()
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration, session: StubURLProtocol.session)
        let first: DeduplicationEndpoint = .init(method: .get)
        let second: DeduplicationEndpoint = .init(method: .post(.init()))

        // When
        let firstKey: ServiceActor.RequestKey = try await serviceActor.requestKey(for: first)
        let secondKey: ServiceActor.RequestKey = try await serviceActor.requestKey(for: second)

        // Then
        XCTAssertNotEqual(firstKey, secondKey)
        XCTAssertEqual(firstKey.url, secondKey.url)
    }
}
