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

extension URLComponents {
    /// Creates a `URLComponents` instance given the provided parameter(s).
    ///
    /// - Parameters:
    ///   - baseURLString: The `Requestable` base URL string value.
    ///   - path:          The `Requestable` path string value.
    ///   - queryItems:    The `Requestable` queryItems.
    init?(baseURLString: String, path: String, queryItems: [QueryItem]? = nil) {
        self.init(string: baseURLString)
        self.path = path
        self.queryItems = queryItems?.compactMap { URLQueryItem(name: $0.name, value: $0.value) }
    }
}
