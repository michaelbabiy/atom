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

extension URLResponse {
    /// Returns `true` if the status code of the `HTTPURLResponse` is not in `200...299` range.
    public var isFailure: Bool { !isSuccess }

    /// Returns `true` if the status code of the `HTTPURLResponse` is in `200...299` range.
    public var isSuccess: Bool {
        guard let response = self as? HTTPURLResponse else {
            return false
        }

        return (200 ... 299).contains(response.statusCode)
    }

    /// Returns a textual representation of this instance, suitable for debugging.
    override public var debugDescription: String {
        guard let response = self as? HTTPURLResponse else {
            return description
        }

        return """
        ↘︎ Response Code: \(response.statusCode)
        ↘︎ Response Headers: \(response.allHeaderFields as NSDictionary)
        """
    }
}
