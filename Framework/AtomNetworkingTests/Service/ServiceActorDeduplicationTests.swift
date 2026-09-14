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

// MARK: - ServiceActorDeduplicationTests

final class ServiceActorDeduplicationTests: XCTestCase {
    func testIdenticalConcurrentGetsCoalesceIntoASingleTransportCall() async throws {
        // Given
        let body: Data = .init("{\"value\":\"atom\"}".utf8)
        let firstProbe: KeyDerivationProbe = .init()
        let secondProbe: KeyDerivationProbe = .init()

        GatedURLProtocol.arm(with: .success(statusCode: 200, data: body))

        let serviceConfiguration: ServiceConfiguration = .init()
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration, session: GatedURLProtocol.session)

        // When
        let first: Task<AtomResponse, Error> = .init {
            try await serviceActor.resume(for: DeduplicationEndpoint(probe: firstProbe))
        }

        await wait(until: { firstProbe.isDerived }, for: "the first caller to register its in-flight request")

        let second: Task<AtomResponse, Error> = .init {
            try await serviceActor.resume(for: DeduplicationEndpoint(probe: secondProbe))
        }

        await wait(until: { secondProbe.isDerived }, for: "the second caller to reach the in-flight lookup")

        GatedURLProtocol.release()

        let firstResponse: AtomResponse = try await first.value
        let secondResponse: AtomResponse = try await second.value

        // Then
        XCTAssertEqual(GatedURLProtocol.requestCount, 1)
        XCTAssertEqual(firstResponse.statusCode, 200)
        XCTAssertEqual(firstResponse.data, body)
        XCTAssertEqual(secondResponse.statusCode, 200)
        XCTAssertEqual(secondResponse.data, body)
    }

    func testGetsDifferingOnlyByHeaderItemsStillCoalesce() async throws {
        // Given
        let body: Data = .init("{\"value\":\"atom\"}".utf8)
        let firstProbe: KeyDerivationProbe = .init()
        let secondProbe: KeyDerivationProbe = .init()

        GatedURLProtocol.arm(with: .success(statusCode: 200, data: body))

        let serviceConfiguration: ServiceConfiguration = .init()
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration, session: GatedURLProtocol.session)

        // When
        let first: Task<AtomResponse, Error> = .init {
            let endpoint: DeduplicationEndpoint = .init(headerItems: [HeaderItem(name: "Authorization", value: "Bearer first")], probe: firstProbe)

            return try await serviceActor.resume(for: endpoint)
        }

        await wait(until: { firstProbe.isDerived }, for: "the first caller to register its in-flight request")

        let second: Task<AtomResponse, Error> = .init {
            let endpoint: DeduplicationEndpoint = .init(headerItems: [HeaderItem(name: "Authorization", value: "Bearer second")], probe: secondProbe)

            return try await serviceActor.resume(for: endpoint)
        }

        await wait(until: { secondProbe.isDerived }, for: "the second caller to reach the in-flight lookup")

        GatedURLProtocol.release()

        let firstResponse: AtomResponse = try await first.value
        let secondResponse: AtomResponse = try await second.value

        // Then
        XCTAssertEqual(GatedURLProtocol.requestCount, 1)
        XCTAssertEqual(firstResponse.data, body)
        XCTAssertEqual(secondResponse.data, body)
    }

    func testGetsDifferingOnlyByAnEmptyVersusAbsentQueryItemsArrayCoalesce() async throws {
        // Given
        let body: Data = .init("{\"value\":\"atom\"}".utf8)
        let firstProbe: KeyDerivationProbe = .init()
        let secondProbe: KeyDerivationProbe = .init()

        GatedURLProtocol.arm(with: .success(statusCode: 200, data: body))

        let serviceConfiguration: ServiceConfiguration = .init()
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration, session: GatedURLProtocol.session)

        // When
        let first: Task<AtomResponse, Error> = .init {
            try await serviceActor.resume(for: DeduplicationEndpoint(queryItems: [], probe: firstProbe))
        }

        await wait(until: { firstProbe.isDerived }, for: "the caller carrying an empty query items array to register its in-flight request")

        let second: Task<AtomResponse, Error> = .init {
            try await serviceActor.resume(for: DeduplicationEndpoint(queryItems: nil, probe: secondProbe))
        }

        await wait(until: { secondProbe.isDerived }, for: "the caller carrying no query items to reach the in-flight lookup")

        GatedURLProtocol.release()

        let firstResponse: AtomResponse = try await first.value
        let secondResponse: AtomResponse = try await second.value

        // Then
        XCTAssertEqual(GatedURLProtocol.requestCount, 1)
        XCTAssertEqual(firstResponse.data, body)
        XCTAssertEqual(secondResponse.data, body)
    }

    func testGetsDifferingByQueryItemsEachReachTheTransport() async throws {
        // Given
        GatedURLProtocol.arm(with: .success(statusCode: 200, data: .init()))

        let serviceConfiguration: ServiceConfiguration = .init()
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration, session: GatedURLProtocol.session)

        // When
        let first: Task<AtomResponse, Error> = .init {
            try await serviceActor.resume(for: DeduplicationEndpoint(queryItems: [QueryItem(name: "flight", value: "1")]))
        }

        let second: Task<AtomResponse, Error> = .init {
            try await serviceActor.resume(for: DeduplicationEndpoint(queryItems: [QueryItem(name: "flight", value: "2")]))
        }

        await wait(until: { GatedURLProtocol.requestCount == 2 }, for: "both callers to park behind the closed gate")

        GatedURLProtocol.release()

        _ = try await first.value
        _ = try await second.value

        // Then
        XCTAssertEqual(GatedURLProtocol.requestCount, 2)
    }

    func testANonGetMethodAlwaysExecutesOnItsOwn() async throws {
        // Given
        GatedURLProtocol.arm(with: .success(statusCode: 200, data: .init()))

        let serviceConfiguration: ServiceConfiguration = .init()
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration, session: GatedURLProtocol.session)

        // When
        let first: Task<AtomResponse, Error> = .init {
            try await serviceActor.resume(for: DeduplicationEndpoint(method: .post(.init())))
        }

        let second: Task<AtomResponse, Error> = .init {
            try await serviceActor.resume(for: DeduplicationEndpoint(method: .post(.init())))
        }

        await wait(until: { GatedURLProtocol.requestCount == 2 }, for: "both callers to park behind the closed gate")

        GatedURLProtocol.release()

        _ = try await first.value
        _ = try await second.value

        // Then
        XCTAssertEqual(GatedURLProtocol.requestCount, 2)
    }

    func testOptingOutOfDeduplicationAlwaysExecutesOnItsOwn() async throws {
        // Given
        GatedURLProtocol.arm(with: .success(statusCode: 200, data: .init()))

        let serviceConfiguration: ServiceConfiguration = .init()
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration, session: GatedURLProtocol.session)

        // When
        let first: Task<AtomResponse, Error> = .init {
            try await serviceActor.resume(for: DeduplicationEndpoint(allowsDeduplication: false))
        }

        let second: Task<AtomResponse, Error> = .init {
            try await serviceActor.resume(for: DeduplicationEndpoint(allowsDeduplication: false))
        }

        await wait(until: { GatedURLProtocol.requestCount == 2 }, for: "both callers to park behind the closed gate")

        GatedURLProtocol.release()

        _ = try await first.value
        _ = try await second.value

        // Then
        XCTAssertEqual(GatedURLProtocol.requestCount, 2)
    }

    func testCancellingOneCallerLeavesTheSharedRequestRunningForTheOther() async throws {
        // Given
        let body: Data = .init("{\"value\":\"atom\"}".utf8)
        let firstProbe: KeyDerivationProbe = .init()
        let secondProbe: KeyDerivationProbe = .init()

        GatedURLProtocol.arm(with: .success(statusCode: 200, data: body))

        let serviceConfiguration: ServiceConfiguration = .init()
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration, session: GatedURLProtocol.session)

        // When
        let first: Task<AtomResponse, Error> = .init {
            try await serviceActor.resume(for: DeduplicationEndpoint(probe: firstProbe))
        }

        await wait(until: { firstProbe.isDerived }, for: "the originating caller to register its in-flight request")

        let second: Task<AtomResponse, Error> = .init {
            try await serviceActor.resume(for: DeduplicationEndpoint(probe: secondProbe))
        }

        await wait(until: { secondProbe.isDerived }, for: "the joining caller to reach the in-flight lookup")

        first.cancel()

        GatedURLProtocol.release()

        let secondResponse: AtomResponse = try await second.value

        // Then
        XCTAssertEqual(GatedURLProtocol.requestCount, 1)
        XCTAssertEqual(secondResponse.statusCode, 200)
        XCTAssertEqual(secondResponse.data, body)
    }

    func testAFailurePropagatesToEveryCallerAwaitingTheSameRequest() async throws {
        // Given
        let firstProbe: KeyDerivationProbe = .init()
        let secondProbe: KeyDerivationProbe = .init()

        GatedURLProtocol.arm(with: .failure(URLError(.timedOut)))

        let serviceConfiguration: ServiceConfiguration = .init()
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration, session: GatedURLProtocol.session)

        // When
        let first: Task<AtomResponse, Error> = .init {
            try await serviceActor.resume(for: DeduplicationEndpoint(probe: firstProbe))
        }

        await wait(until: { firstProbe.isDerived }, for: "the first caller to register its in-flight request")

        let second: Task<AtomResponse, Error> = .init {
            try await serviceActor.resume(for: DeduplicationEndpoint(probe: secondProbe))
        }

        await wait(until: { secondProbe.isDerived }, for: "the second caller to reach the in-flight lookup")

        GatedURLProtocol.release()

        var firstError: AtomError?
        var secondError: AtomError?

        do {
            _ = try await first.value
        } catch {
            firstError = error as? AtomError
        }

        do {
            _ = try await second.value
        } catch {
            secondError = error as? AtomError
        }

        // Then
        XCTAssertEqual(GatedURLProtocol.requestCount, 1)
        XCTAssertEqual(firstError?.stringValue, "session")
        XCTAssertEqual(secondError?.stringValue, "session")
    }

    func testTheInFlightEntryIsRemovedOnceTheOriginatingCallFinishes() async throws {
        // Given
        GatedURLProtocol.arm(with: .success(statusCode: 200, data: .init()))
        GatedURLProtocol.release()

        let serviceConfiguration: ServiceConfiguration = .init()
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration, session: GatedURLProtocol.session)

        // When
        _ = try await serviceActor.resume(for: DeduplicationEndpoint())

        // Then
        let inFlightCount: Int = await serviceActor.inFlightRequests.count

        XCTAssertEqual(GatedURLProtocol.requestCount, 1)
        XCTAssertEqual(inFlightCount, 0)
    }

    func testALaterIdenticalRequestStartsFreshRatherThanJoiningACompletedOne() async throws {
        // Given
        GatedURLProtocol.arm(with: .success(statusCode: 200, data: .init()))
        GatedURLProtocol.release()

        let serviceConfiguration: ServiceConfiguration = .init()
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration, session: GatedURLProtocol.session)

        // When
        _ = try await serviceActor.resume(for: DeduplicationEndpoint())
        _ = try await serviceActor.resume(for: DeduplicationEndpoint())

        // Then
        XCTAssertEqual(GatedURLProtocol.requestCount, 2)
    }

    /// Waits until a condition holds, failing the test rather than hanging the suite if it never does.
    ///
    /// The condition is the signal. The interval between checks only keeps the poll from spinning, and the deadline
    /// only turns a broken expectation into a failure, so no test here waits a guessed interval for work to happen.
    ///
    /// - Parameters:
    ///   - condition:   The condition to poll.
    ///   - description: A description of what is being waited on, used in the failure message.
    ///   - file:        The file the wait was requested from.
    ///   - line:        The line the wait was requested from.
    private func wait(
        until condition: @Sendable () -> Bool,
        for description: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline: Date = .init(timeIntervalSinceNow: 5)

        while Date() < deadline {
            if condition() {
                return
            }

            try? await Task.sleep(nanoseconds: 1_000_000)
        }

        XCTFail("Timed out waiting for \(description).", file: file, line: line)
    }
}
