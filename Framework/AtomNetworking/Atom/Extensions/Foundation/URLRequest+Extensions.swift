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

import Foundation

// MARK: - Helper Properties and Methods

extension URLRequest {
    /// Returns a textual representation of this instance, suitable for debugging.
    ///
    /// If the request does not contain a valid URL, default description will be returned
    /// without evaluating remaining properties of this request.
    var debugDescription: String {
        guard let url else {
            return description
        }

        let body = httpBody ?? .init()
        let headers = allHTTPHeaderFields ?? .init()
        let method = httpMethod ?? .init()

        return """
        ↖︎ Request Body: \(body.jsonObjectOrSelf)
        ↖︎ Request Headers: \(headers)
        ↖︎ Request Method: \(method)
        ↖︎ Request URL: \(url)
        """
    }

    /// Creates a `URLRequest` instance given the provided parameter(s).
    ///
    /// - Parameters:
    ///   - requestable: The `Requesatble` item containing all required data to initialize `self`.
    init(requestable: Requestable) throws(AtomError) {
        // Validate base URL, get a string value if validation succeeds.
        let baseURLString = try requestable.baseURL().stringValue

        // Validate URL path, get a string value if validation succeeds.
        let pathString = try requestable.path().stringValue

        // Add query parameters, if any.
        guard let url = URLComponents(baseURLString: baseURLString, path: pathString, queryItems: requestable.queryItems)?.url else {
            throw .requestable(.invalidURL)
        }

        // Initialize `self`.
        self.init(url: url)

        // Set additional values.
        self.allHTTPHeaderFields = requestable.headerItems?.dictionary
        self.httpBody = requestable.method.body
        self.httpMethod = requestable.method.stringValue
    }
}
