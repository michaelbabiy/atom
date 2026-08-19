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
import XCTest

final class ConnectivityErrorTests: XCTestCase {
    func testInitializeDefaultsInterfaceAndUnderlyingErrorToNil() {
        // Given, When
        let error: ConnectivityError = .init(reason: .gated)

        // Then
        XCTAssertEqual(error.reason, .gated)
        XCTAssertNil(error.interface)
        XCTAssertNil(error.underlyingError)
    }

    func testInitializeRoundTripsAllProperties() {
        // Given
        let underlyingError: NSError = .init(domain: "domain", code: 100, userInfo: nil)

        // When
        let error: ConnectivityError = .init(reason: .transport, interface: .cellular, underlyingError: underlyingError)

        // Then
        XCTAssertEqual(error.reason, .transport)
        XCTAssertEqual(error.interface, .cellular)
        XCTAssertNotNil(error.underlyingError)
    }

    func testGatedDescriptionOmitsInterfaceClauseWhenInterfaceIsUnknown() {
        // Given, When
        let error: ConnectivityError = .init(reason: .gated)

        // Then
        XCTAssertEqual(error.description, "🧨 Atom refused the request because the device has no usable network path.")
    }

    func testGatedDescriptionIncludesLastInterfaceClause() {
        // Given, When
        let error: ConnectivityError = .init(reason: .gated, interface: .wifi)

        // Then
        XCTAssertEqual(error.description, "🧨 Atom refused the request because the device has no usable network path. 📡 Last interface: wifi.")
    }

    func testTransportDescriptionOmitsErrorClauseWhenUnderlyingErrorIsAbsent() {
        // Given, When
        let error: ConnectivityError = .init(reason: .transport)

        // Then
        XCTAssertEqual(error.description, "🧨 URLSession could not send the request because the device is not connected.")
    }

    func testTransportDescriptionIncludesUnderlyingErrorClause() {
        // Given
        let underlyingError: NSError = .init(domain: "domain", code: 100, userInfo: nil)

        // When
        let error: ConnectivityError = .init(reason: .transport, underlyingError: underlyingError)

        // Then
        XCTAssertEqual(error.description, "🧨 URLSession could not send the request because the device is not connected. 💥 Error: Error Domain=domain Code=100 \"(null)\"")
    }
}
