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

// MARK: - PluginRecorder

final class PluginRecorder: @unchecked Sendable {
    // MARK: - Properties

    /// The lock guarding `recorded`, since plugins are `Sendable` and may record from any isolation.
    private let lock: NSLock = .init()

    /// The events recorded so far, in the order they arrived.
    private var recorded: [String] = .init()

    // MARK: - Computed Properties

    /// Returns the events recorded so far, in the order they arrived.
    var events: [String] {
        lock.lock()

        defer { lock.unlock() }

        return recorded
    }

    // MARK: - Functions

    /// Appends an event to the recording.
    ///
    /// - Parameters:
    ///   - event: The event to append.
    func record(_ event: String) {
        lock.lock()

        defer { lock.unlock() }

        recorded.append(event)
    }
}
