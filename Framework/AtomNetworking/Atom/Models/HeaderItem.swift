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

/// A single name-value pair from the header portion of a request.
public struct HeaderItem: RequestableItem, Sendable {
    // MARK: - Properties

    /// The name of the header item.
    public let name: String

    /// The value of the header item.
    public let value: String

    // MARK: - Lifecycle

    /// Creates a `HeaderItem` instance given the provided parameter(s).
    ///
    /// - Parameters:
    ///   - name:  The name of the header item.
    ///   - value: The value of the header item.
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}
