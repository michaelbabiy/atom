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

final class ServiceConfigurationExtensionsTests: XCTestCase {
    func testEphemeralConfigurationResolvesToASessionThatKeepsNothingShared() {
        // Given
        let serviceConfiguration: ServiceConfiguration = .init(configuration: .ephemeral)

        // When
        let sessionConfiguration: URLSessionConfiguration = serviceConfiguration.sessionConfiguration

        // Then
        XCTAssertNil(sessionConfiguration.identifier)
        XCTAssertFalse(sessionConfiguration.urlCache === URLCache.shared)
    }

    func testDefaultConfigurationResolvesToASessionBackedByTheSharedCache() {
        // Given
        let serviceConfiguration: ServiceConfiguration = .init(configuration: .default)

        // When
        let sessionConfiguration: URLSessionConfiguration = serviceConfiguration.sessionConfiguration

        // Then
        XCTAssertNil(sessionConfiguration.identifier)
        XCTAssertTrue(sessionConfiguration.urlCache === URLCache.shared)
    }

    func testBackgroundConfigurationCarriesTheIdentifierItWasGiven() {
        // Given
        let serviceConfiguration: ServiceConfiguration = .init(configuration: .background("com.alaskaair.atom.tests"))

        // When
        let sessionConfiguration: URLSessionConfiguration = serviceConfiguration.sessionConfiguration

        // Then
        XCTAssertEqual(sessionConfiguration.identifier, "com.alaskaair.atom.tests")
    }

    func testBothTimeoutIntervalsReachTheSessionConfiguration() {
        // Given
        let serviceConfiguration: ServiceConfiguration = .init(timeout: ServiceTimeout(request: 12, resource: 34))

        // When
        let sessionConfiguration: URLSessionConfiguration = serviceConfiguration.sessionConfiguration

        // Then
        XCTAssertEqual(sessionConfiguration.timeoutIntervalForRequest, 12)
        XCTAssertEqual(sessionConfiguration.timeoutIntervalForResource, 34)
    }

    func testTheMultipathServiceTypeReachesTheSessionConfiguration() {
        // Given
        let serviceConfiguration: ServiceConfiguration = .init(multipathServiceType: .handover)

        // When
        let sessionConfiguration: URLSessionConfiguration = serviceConfiguration.sessionConfiguration

        // Then
        XCTAssertEqual(sessionConfiguration.multipathServiceType, .handover)
    }
}
