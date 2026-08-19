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

// MARK: - ConnectivityPluginTests

final class ConnectivityPluginTests: XCTestCase {
    func testSendRefusesWhenPathHasStayedUnsatisfiedPastSettlingInterval() async {
        // Given
        let snapshot: ConnectivitySnapshot = .init(status: .unsatisfied, interface: .wifi, changedAt: ContinuousClock().now - .seconds(10))
        let plugin: ConnectivityPlugin = .init(monitor: StubMonitor(value: snapshot))

        // When
        var thrownError: AtomError?
        var interface: ConnectivitySnapshot.Interface?
        var reason: ConnectivityError.Reason?

        do {
            _ = try await plugin.send(ConnectivityEndpoint(), next: NextHandler { _ in .success })
        } catch {
            thrownError = error

            if case let .connectivity(connectivityError) = error {
                interface = connectivityError.interface
                reason = connectivityError.reason
            }
        }

        // Then
        XCTAssertEqual(thrownError?.stringValue, "connectivity")
        XCTAssertEqual(reason, .gated)
        XCTAssertEqual(interface, .wifi)
    }

    func testSendPassesThroughWhenPathIsUnsatisfiedButHasNotSettled() async throws {
        // Given
        let snapshot: ConnectivitySnapshot = .init(status: .unsatisfied, interface: .cellular, changedAt: ContinuousClock().now)
        let plugin: ConnectivityPlugin = .init(monitor: StubMonitor(value: snapshot))

        // When
        let response: AtomResponse = try await plugin.send(ConnectivityEndpoint(), next: NextHandler { _ in .success })

        // Then
        XCTAssertEqual(response.statusCode, 200)
    }

    func testSendPassesThroughWhenPathIsSatisfiedHoweverOldTheSnapshot() async throws {
        // Given
        let snapshot: ConnectivitySnapshot = .init(status: .satisfied, interface: .wifi, changedAt: ContinuousClock().now - .seconds(10))
        let plugin: ConnectivityPlugin = .init(monitor: StubMonitor(value: snapshot))

        // When
        let response: AtomResponse = try await plugin.send(ConnectivityEndpoint(), next: NextHandler { _ in .success })

        // Then
        XCTAssertEqual(response.statusCode, 200)
    }

    func testSendPassesThroughWhenPathIsUnknownHoweverOldTheSnapshot() async throws {
        // Given
        let snapshot: ConnectivitySnapshot = .init(status: .unknown, changedAt: ContinuousClock().now - .seconds(10))
        let plugin: ConnectivityPlugin = .init(monitor: StubMonitor(value: snapshot))

        // When
        let response: AtomResponse = try await plugin.send(ConnectivityEndpoint(), next: NextHandler { _ in .success })

        // Then
        XCTAssertEqual(response.statusCode, 200)
    }

    func testSendNeverCallsNextWhenItRefuses() async {
        // Given
        let snapshot: ConnectivitySnapshot = .init(status: .unsatisfied, interface: .wifi, changedAt: ContinuousClock().now - .seconds(10))
        let plugin: ConnectivityPlugin = .init(monitor: StubMonitor(value: snapshot))
        let tracker: NextTracker = .init()

        // When
        var thrownError: AtomError?

        do {
            _ = try await plugin.send(ConnectivityEndpoint(), next: NextHandler { _ in
                tracker.markCalled()

                return .success
            })
        } catch {
            thrownError = error
        }

        // Then
        XCTAssertEqual(thrownError?.stringValue, "connectivity")
        XCTAssertEqual(tracker.isCalled, false)
    }

    func testDefaultSettlingIntervalIsThreeSeconds() {
        // Given, When
        let settlingInterval: Duration = ConnectivityPlugin.defaultSettlingInterval

        // Then
        XCTAssertEqual(settlingInterval, .seconds(3))
    }

    func testSendRefusesImmediatelyWhenSettlingIntervalIsZero() async {
        // Given
        let snapshot: ConnectivitySnapshot = .init(status: .unsatisfied, interface: .wired, changedAt: ContinuousClock().now)
        let plugin: ConnectivityPlugin = .init(monitor: StubMonitor(value: snapshot), settlingInterval: .zero)

        // When
        var thrownError: AtomError?
        var reason: ConnectivityError.Reason?

        do {
            _ = try await plugin.send(ConnectivityEndpoint(), next: NextHandler { _ in .success })
        } catch {
            thrownError = error

            if case let .connectivity(connectivityError) = error {
                reason = connectivityError.reason
            }
        }

        // Then
        XCTAssertEqual(thrownError?.stringValue, "connectivity")
        XCTAssertEqual(reason, .gated)
    }

    func testSendRefusesWithoutAnInterfaceWhenSnapshotHasNone() async {
        // Given
        let snapshot: ConnectivitySnapshot = .init(status: .unsatisfied, changedAt: ContinuousClock().now - .seconds(10))
        let plugin: ConnectivityPlugin = .init(monitor: StubMonitor(value: snapshot))

        // When
        var thrownError: AtomError?
        var interface: ConnectivitySnapshot.Interface?
        var reason: ConnectivityError.Reason?

        do {
            _ = try await plugin.send(ConnectivityEndpoint(), next: NextHandler { _ in .success })
        } catch {
            thrownError = error

            if case let .connectivity(connectivityError) = error {
                interface = connectivityError.interface
                reason = connectivityError.reason
            }
        }

        // Then
        XCTAssertEqual(thrownError?.stringValue, "connectivity")
        XCTAssertEqual(reason, .gated)
        XCTAssertNil(interface)
    }
}
