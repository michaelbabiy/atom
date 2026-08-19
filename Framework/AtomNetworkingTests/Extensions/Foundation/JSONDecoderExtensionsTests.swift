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

final class JSONDecoderExtensionsTests: XCTestCase {
    func testDecodingASupportedTypeReturnsTheDecodedValue() throws {
        // Given
        let decoder: JSONDecoder = .init()
        let data: Data = .init("\"QUJD\"".utf8)

        // When
        let decoded: Data = try decoder.decode(type: Data.self, from: data)

        // Then
        XCTAssertEqual(decoded, Data("ABC".utf8))
    }

    func testADecodingFailureIsReportedAsADecoderError() {
        // Given
        let decoder: JSONDecoder = .init()
        let data: Data = .init("{}".utf8)

        // When
        var expectedError: AtomError?

        do {
            _ = try decoder.decode(type: Data.self, from: data)
        } catch {
            expectedError = error
        }

        // Then
        XCTAssertEqual(expectedError?.stringValue, "decoder")
    }
}
