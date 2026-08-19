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

final class TokenCredentialExtensionsTests: XCTestCase {
    func testDecodingAServicePayloadDerivesTheExpirationFromExpiresIn() throws {
        // Given
        let json = "{\"access_token\":\"access\",\"expires_in\":3600,\"refresh_token\":\"refresh\"}"

        // When
        let credential: TokenCredential = try JSONDecoder().decode(TokenCredential.self, from: Data(json.utf8))

        // Then
        XCTAssertEqual(credential.accessToken, "access")
        XCTAssertEqual(credential.refreshToken, "refresh")
        XCTAssertEqual(credential.expiresAt.timeIntervalSinceNow, 3600, accuracy: 30)
    }

    func testDecodingAStoredPayloadKeepsTheExpirationItWasSavedWith() throws {
        // Given
        let json = "{\"access_token\":\"access\",\"expires_at\":0,\"expires_in\":3600,\"refresh_token\":\"refresh\"}"

        // When
        let credential: TokenCredential = try JSONDecoder().decode(TokenCredential.self, from: Data(json.utf8))

        // Then
        XCTAssertEqual(credential.expiresAt, Date(timeIntervalSinceReferenceDate: 0))
    }

    func testDecodingAPayloadCarryingNeitherExpirationFieldFails() {
        // Given
        let json = "{\"access_token\":\"access\",\"refresh_token\":\"refresh\"}"

        // When
        var expectedError: Error?

        do {
            _ = try JSONDecoder().decode(TokenCredential.self, from: Data(json.utf8))
        } catch {
            expectedError = error
        }

        // Then
        guard case .dataCorrupted = expectedError as? DecodingError else {
            return XCTFail("Expected a data corrupted DecodingError, got \(String(describing: expectedError)).")
        }
    }

    func testEncodingWritesExpiresAtAndOmitsExpiresIn() throws {
        // Given
        let credential: TokenCredential = .init(accessToken: "access", expiresAt: Date(timeIntervalSinceReferenceDate: 0), refreshToken: "refresh")

        // When
        let encoded: Data = try JSONEncoder().encode(credential)
        let object: [String: Any] = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

        // Then
        XCTAssertEqual(object["access_token"] as? String, "access")
        XCTAssertEqual(object["refresh_token"] as? String, "refresh")
        XCTAssertEqual(object["expires_at"] as? Double, 0)
        XCTAssertNil(object["expires_in"])
    }

    func testRequiresRefreshFollowsTheExpirationDate() {
        // Given
        let expired: TokenCredential = .init(accessToken: "access", expiresAt: .distantPast, refreshToken: "refresh")
        let valid: TokenCredential = .init(accessToken: "access", expiresAt: .distantFuture, refreshToken: "refresh")

        // Then
        XCTAssertTrue(expired.requiresRefresh)
        XCTAssertFalse(valid.requiresRefresh)
    }
}
