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

final class AtomErrorExtensionsTests: XCTestCase {
    func testIsAuthorizationFailure() {
        // Given, When
        let error: AtomError = .response(AtomResponse(statusCode: 401))

        // Then
        XCTAssertTrue(error.isAuthorizationFailure)
    }

    func testIsBadRequestIsTrueOnlyForAFourHundredResponse() {
        // Given, When
        let badRequest: AtomError = .response(AtomResponse(statusCode: 400))
        let unauthorized: AtomError = .response(AtomResponse(statusCode: 401))

        // Then
        XCTAssertTrue(badRequest.isBadRequest)
        XCTAssertFalse(unauthorized.isBadRequest)
        XCTAssertFalse(AtomError.unexpected.isBadRequest)
    }

    func testIsOfflineIsTrueOnlyForConnectivity() {
        // Given, When
        let gated: AtomError = .connectivity(ConnectivityError(reason: .gated))
        let transport: AtomError = .connectivity(ConnectivityError(reason: .transport))
        let session: AtomError = .session(URLError(.notConnectedToInternet))

        // Then
        XCTAssertTrue(gated.isOffline)
        XCTAssertTrue(transport.isOffline)
        XCTAssertFalse(session.isOffline)
        XCTAssertFalse(AtomError.unexpected.isOffline)
    }

    func testDataDecodeIfPresentErrorData() throws {
        // Given
        let json = ["key": "value"]
        let data = try JSONEncoder().encode(json)
        let error: AtomError = .response(AtomResponse(data: data, response: nil))

        // When
        let dictionary = try error.decodeIfPresent(as: [String: String].self)

        // Then
        XCTAssertNotNil(dictionary)
        XCTAssertEqual(dictionary?["key"], "value")
    }
}
