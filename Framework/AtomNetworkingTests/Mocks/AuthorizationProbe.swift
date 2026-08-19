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

// MARK: - AuthorizationProbe

/// Counts the callers that reached the point where authorization decides whether a refresh is needed.
///
/// Authorization reads `requiresAuthorization` off the request, and then reads the stored credential and the
/// in-flight refresh task without suspending in between. A test that observes an arrival therefore knows that
/// caller has already either started a refresh or joined the one in progress.
///
/// That is what lets a test place callers on both sides of the moment a refresh completes on purpose, rather than
/// spawning a crowd and hoping the timing lands somewhere useful.
final class AuthorizationProbe: @unchecked Sendable {
    // MARK: - Properties

    /// The lock guarding the count, since callers arrive from whichever isolation each one is running on.
    private let lock: NSLock = .init()

    /// The number of callers that reached the authorization decision.
    private var count: Int = 0

    // MARK: - Computed Properties

    /// Returns the number of callers that reached the authorization decision.
    var arrivals: Int {
        lock.lock()

        defer { lock.unlock() }

        return count
    }

    // MARK: - Functions

    /// Records that a caller reached the authorization decision.
    func markArrived() {
        lock.lock()

        defer { lock.unlock() }

        count += 1
    }
}
