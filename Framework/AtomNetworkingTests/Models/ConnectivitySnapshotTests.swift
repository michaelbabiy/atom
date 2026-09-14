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
import Network
import XCTest

final class ConnectivitySnapshotTests: XCTestCase {
    func testStatusInitializesSatisfiedFromSatisfiedPathStatus() {
        // Given
        let pathStatus: NWPath.Status = .satisfied

        // When
        let status: ConnectivitySnapshot.Status = .init(pathStatus)

        // Then
        XCTAssertEqual(status, .satisfied)
    }

    func testStatusInitializesUnsatisfiedFromUnsatisfiedPathStatus() {
        // Given
        let pathStatus: NWPath.Status = .unsatisfied

        // When
        let status: ConnectivitySnapshot.Status = .init(pathStatus)

        // Then
        XCTAssertEqual(status, .unsatisfied)
    }

    func testStatusInitializesSatisfiedFromRequiresConnectionPathStatus() {
        // Given
        let pathStatus: NWPath.Status = .requiresConnection

        // When
        let status: ConnectivitySnapshot.Status = .init(pathStatus)

        // Then
        XCTAssertEqual(status, .satisfied)
    }

    func testInitializeDefaultsInterfaceToNil() {
        // Given
        let clock: ContinuousClock = .init()

        // When
        let snapshot: ConnectivitySnapshot = .init(status: .satisfied, changedAt: clock.now)

        // Then
        XCTAssertEqual(snapshot.status, .satisfied)
        XCTAssertNil(snapshot.interface)
    }

    func testInitializeRoundTripsAllProperties() {
        // Given
        let clock: ContinuousClock = .init()
        let changedAt = clock.now

        // When
        let snapshot: ConnectivitySnapshot = .init(status: .unsatisfied, interface: .cellular, changedAt: changedAt)

        // Then
        XCTAssertEqual(snapshot.status, .unsatisfied)
        XCTAssertEqual(snapshot.interface, .cellular)
        XCTAssertEqual(snapshot.changedAt, changedAt)
    }
}
