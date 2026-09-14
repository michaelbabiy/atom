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

// MARK: - NextHandlerTests

final class NextHandlerTests: XCTestCase {
    func testCallAsFunctionPropagatesAtomErrorUnchanged() async {
        // Given
        let handler: NextHandler = .init { _ in throw AtomError.response(AtomResponse(statusCode: 401)) }

        // When
        var thrownError: AtomError?
        var statusCode: Int?

        do {
            _ = try await handler(NextHandlerEndpoint())
        } catch {
            thrownError = error

            if case let .response(response) = error {
                statusCode = response.statusCode
            }
        }

        // Then
        XCTAssertEqual(thrownError?.stringValue, "response")
        XCTAssertEqual(statusCode, 401)
    }

    func testCallAsFunctionCollapsesForeignErrorToUnexpected() async {
        // Given
        let handler: NextHandler = .init { _ in throw NSError(domain: "com.alaskaair.atom", code: 42, userInfo: nil) }

        // When
        var thrownError: AtomError?

        do {
            _ = try await handler(NextHandlerEndpoint())
        } catch {
            thrownError = error
        }

        // Then
        XCTAssertEqual(thrownError?.stringValue, "unexpected")
    }

    func testCallAsFunctionReturnsResponseUnchanged() async throws {
        // Given
        let handler: NextHandler = .init { _ in AtomResponse(statusCode: 204) }

        // When
        let response: AtomResponse = try await handler(NextHandlerEndpoint())

        // Then
        XCTAssertEqual(response.statusCode, 204)
        XCTAssertTrue(response.isSuccess)
    }
}
