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

import AtomNetworking
import Foundation

// MARK: - Joke

struct Joke: Model {
    /// The id of the joke.
    let id: String

    /// The joke itself, text.
    let value: String
}

extension Joke {
    static let `default`: Joke = .init(
        id: "id",
        value: "If Chuck Norris writes code with bugs, the bugs fix themselves."
    )
}
