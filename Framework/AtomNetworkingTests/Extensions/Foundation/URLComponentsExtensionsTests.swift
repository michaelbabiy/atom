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

final class URLComponentsExtensionsTests: XCTestCase {
    func testAnEmptyQueryItemsArrayResolvesToTheSameURLAsNoQueryItems() {
        // Given
        let empty: URLComponents? = .init(baseURLString: "https://api.alaskaair.com", path: "/path", queryItems: [])
        let absent: URLComponents? = .init(baseURLString: "https://api.alaskaair.com", path: "/path", queryItems: nil)

        // When
        let emptyURL: String? = empty?.url?.absoluteString
        let absentURL: String? = absent?.url?.absoluteString

        // Then
        XCTAssertEqual(emptyURL, absentURL)
        XCTAssertEqual(emptyURL, "https://api.alaskaair.com/path")
        XCTAssertNil(empty?.queryItems)
    }

    func testQueryItemsAreCarriedIntoTheResolvedURL() {
        // Given
        let queryItems: [QueryItem] = [QueryItem(name: "flight", value: "1"), QueryItem(name: "date", value: "today")]

        // When
        let components: URLComponents? = .init(baseURLString: "https://api.alaskaair.com", path: "/path", queryItems: queryItems)

        // Then
        XCTAssertEqual(components?.url?.absoluteString, "https://api.alaskaair.com/path?flight=1&date=today")
    }
}
