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

final class AuthenticationMethodExtensionsTests: XCTestCase {
    func testBasicMethodProducesABase64EncodedAuthorizationHeader() {
        // Given
        let credential: BasicCredential = .init(password: "password", username: "username")

        // When
        let headerItem: HeaderItem = AuthenticationMethod.basic(credential).authorizationHeaderItem

        // Then
        XCTAssertEqual(headerItem.name, "Authorization")
        XCTAssertEqual(headerItem.value, "Basic dXNlcm5hbWU6cGFzc3dvcmQ=")
    }

    func testBearerMethodProducesABearerHeaderCarryingTheStoredAccessToken() throws {
        // Given
        let endpoint: AuthorizationEndpoint = try .init(host: "api.alaskaair.com", path: "/token")
        let credential: ClientCredential = .init(id: "id", secret: "secret")
        let writable: StubTokenCredentialWritable = .init()

        // When
        let headerItem: HeaderItem = AuthenticationMethod.bearer(endpoint, credential, writable).authorizationHeaderItem

        // Then
        XCTAssertEqual(headerItem.name, "Authorization")
        XCTAssertEqual(headerItem.value, "Bearer \(writable.tokenCredential.accessToken)")
    }

    func testNoneMethodProducesAnEmptyAuthorizationHeaderValue() {
        // Given, When
        let headerItem: HeaderItem = AuthenticationMethod.none.authorizationHeaderItem

        // Then
        XCTAssertEqual(headerItem.name, "Authorization")
        XCTAssertTrue(headerItem.value.isEmpty)
    }
}
