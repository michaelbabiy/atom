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

// MARK: - KeyDerivationProbe

/// Records that a caller resolved its request into a de-duplication key.
///
/// The actor derives the key synchronously, and reaches the in-flight lookup without suspending in between. A test
/// that observes a derivation therefore knows the caller either joined an in-flight request or registered its own,
/// which is what makes an overlapping-caller test deterministic rather than timing hopeful.
final class KeyDerivationProbe: @unchecked Sendable {
    // MARK: - Properties

    /// The lock guarding the count, since a request is keyed on whichever thread the actor is running on.
    private let lock: NSLock = .init()

    /// The number of times a key was derived from the request carrying this probe.
    private var derivations: Int = 0

    // MARK: - Computed Properties

    /// Returns `true` once a key was derived from the request carrying this probe.
    var isDerived: Bool {
        lock.lock()

        defer { lock.unlock() }

        return derivations > 0
    }

    // MARK: - Functions

    /// Records that a key was derived from the request carrying this probe.
    func markDerived() {
        lock.lock()

        defer { lock.unlock() }

        derivations += 1
    }
}
