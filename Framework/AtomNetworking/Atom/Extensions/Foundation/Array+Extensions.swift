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

extension Array where Element: RequestableItem {
    /// Returns an array of `HeaderItem` as a dictionary.
    var dictionary: [String: String] {
        reduce([:]) {
            var result = $0
            result[$1.name] = $1.value

            return result
        }
    }
}

// MARK: - Array + Model

/// Adds the ability to specify an array as the expected decoded type.
extension Array: Model where Element: Model {}

// MARK: - ExpressibleByDictionaryLiteral

extension Array: @retroactive ExpressibleByDictionaryLiteral where Element: RequestableItem {
    public init(dictionaryLiteral elements: (String, String)...) {
        self.init()

        for element in elements {
            append(.init(name: element.0, value: element.1))
        }
    }
}
