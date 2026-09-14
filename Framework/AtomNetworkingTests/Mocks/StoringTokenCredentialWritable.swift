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
import Foundation

// MARK: - StoringTokenCredentialWritable

/// A credential store that keeps what is written to it, and counts the reads and the writes.
///
/// A store that discards writes cannot answer the question a refresh test asks. If every read returns the same
/// expired credential no matter what the library did, then "refreshed, and stored the result" and "refreshed, and
/// threw the result away" look identical from the outside, and so does "refreshed twice". Keeping the value is what
/// makes those outcomes tell apart.
///
/// The write count carries its own meaning. A refreshed credential belongs in the store once, because a real
/// conforming type is writing to somewhere durable such as the keychain.
final class StoringTokenCredentialWritable: TokenCredentialWritable, @unchecked Sendable {
    // MARK: - Properties

    /// The lock guarding the stored credential and the counts, since authorization reads and writes from whichever
    /// isolation the calling task is running on.
    private let lock: NSLock = .init()

    /// The credential currently held by the store.
    private var credential: TokenCredential

    /// The number of times the credential was read.
    private var reads: Int = 0

    /// The number of times the credential was written.
    private var writes: Int = 0

    // MARK: - Computed Properties

    /// The credential Atom reads and writes.
    var tokenCredential: TokenCredential {
        get {
            lock.lock()

            defer { lock.unlock() }

            reads += 1

            return credential
        }
        set {
            lock.lock()

            defer { lock.unlock() }

            writes += 1
            credential = newValue
        }
    }

    /// Returns the number of times the credential was read.
    var readCount: Int {
        lock.lock()

        defer { lock.unlock() }

        return reads
    }

    /// Returns the credential currently held by the store, without counting the access as a read.
    ///
    /// A test inspecting the store should not disturb the counts it is about to assert on.
    var storedCredential: TokenCredential {
        lock.lock()

        defer { lock.unlock() }

        return credential
    }

    /// Returns the number of times the credential was written.
    var writeCount: Int {
        lock.lock()

        defer { lock.unlock() }

        return writes
    }

    // MARK: - Lifecycle

    /// Creates a `StoringTokenCredentialWritable` instance given the provided parameter(s).
    ///
    /// - Parameters:
    ///   - credential: The credential the store starts out holding.
    init(credential: TokenCredential) {
        self.credential = credential
    }
}
