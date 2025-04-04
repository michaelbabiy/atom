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

final class ServiceConfigurationTests: XCTestCase {
    func testInitializeWithDefaultParameters() {
        // Given, When
        let serviceConfiguration: ServiceConfiguration = .init()

        // Then
        XCTAssertEqual(serviceConfiguration.dispatchQueue, .main)
        XCTAssertEqual(serviceConfiguration.configuration, .ephemeral)
        XCTAssertFalse(serviceConfiguration.isLogEnabled)
    }

    func testInitializeWithTimeout() {
        // Given, When
        let timeout: ServiceTimeout = .init(request: 60, resource: 60)
        let serviceConfiguration: ServiceConfiguration = .init(timeout: timeout)

        // Then
        XCTAssertEqual(serviceConfiguration.timeout.request, 60)
        XCTAssertEqual(serviceConfiguration.timeout.resource, 60)
    }
}
