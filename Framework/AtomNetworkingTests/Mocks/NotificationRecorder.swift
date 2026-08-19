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

// MARK: - NotificationRecorder

/// Counts the failure notifications Atom posts while refreshing a credential or authorizing a request.
///
/// Both notifications are observed together on purpose. Which of the two a given failure produces is the whole
/// question, so a recorder that watched only one could not tell "posted the other one" apart from "posted nothing".
final class NotificationRecorder: @unchecked Sendable {
    // MARK: - Properties

    /// The lock guarding the counts, since a notification is delivered on whichever thread posted it.
    private let lock: NSLock = .init()

    /// The number of `Atom.didFailToAuthorizeRequest` notifications observed.
    private var authorizationFailures: Int = 0

    /// The number of `Atom.didFailToRefreshAccessToken` notifications observed.
    private var refreshFailures: Int = 0

    /// The observer tokens to withdraw once the recorder goes away.
    private var tokens: [any NSObjectProtocol] = .init()

    // MARK: - Computed Properties

    /// Returns the number of `Atom.didFailToAuthorizeRequest` notifications observed.
    var authorizationFailureCount: Int {
        lock.lock()

        defer { lock.unlock() }

        return authorizationFailures
    }

    /// Returns the number of `Atom.didFailToRefreshAccessToken` notifications observed.
    var refreshFailureCount: Int {
        lock.lock()

        defer { lock.unlock() }

        return refreshFailures
    }

    // MARK: - Lifecycle

    /// Creates a `NotificationRecorder` instance already observing both notifications.
    init() {
        let center: NotificationCenter = .default

        tokens.append(center.addObserver(forName: Atom.didFailToRefreshAccessToken, object: nil, queue: nil) { [weak self] _ in
            self?.recordRefreshFailure()
        })

        tokens.append(center.addObserver(forName: Atom.didFailToAuthorizeRequest, object: nil, queue: nil) { [weak self] _ in
            self?.recordAuthorizationFailure()
        })
    }

    /// Withdraws both observers so a later test cannot record into a recorder that is done.
    deinit {
        tokens.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - Functions

    /// Records that an authorization failure notification arrived.
    private func recordAuthorizationFailure() {
        lock.lock()

        defer { lock.unlock() }

        authorizationFailures += 1
    }

    /// Records that a refresh failure notification arrived.
    private func recordRefreshFailure() {
        lock.lock()

        defer { lock.unlock() }

        refreshFailures += 1
    }
}
