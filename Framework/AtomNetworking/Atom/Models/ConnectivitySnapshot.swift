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

// MARK: - ConnectivitySnapshot

/// A point in time reading of the device's network path.
///
/// A snapshot pairs the current `status` with the moment that status was last *entered*. The pairing is what
/// makes debounced gating possible: knowing the path is unsatisfied is not enough, since a handoff between
/// Wi-Fi and cellular briefly reports exactly that. Knowing it has *stayed* unsatisfied is enough.
///
/// For more information, see `ConnectivityMonitoring` and `ConnectivityPlugin`.
public struct ConnectivitySnapshot: Sendable, Equatable {
    // MARK: - Nested Types

    // MARK: - Status

    /// The usability of the device's network path.
    public enum Status: Sendable, Equatable {
        /// The path is usable.
        case satisfied

        /// The path has not reported yet.
        ///
        /// Unknown never gates a request - it is a guess.
        case unknown

        /// The path is not usable.
        case unsatisfied
    }

    // MARK: - Interface

    /// The kind of interface a path is using.
    public enum Interface: Sendable, Equatable {
        /// A cellular interface.
        case cellular

        /// An interface Atom does not classify.
        case other

        /// A Wi-Fi interface.
        case wifi

        /// A wired ethernet interface.
        case wired
    }

    // MARK: - Properties

    /// The moment `status` was last entered, on the monotonic continuous clock.
    public let changedAt: ContinuousClock.Instant

    /// The kind of interface the path is using, or the one it was last using while the path is unsatisfied.
    public let interface: Interface?

    /// The usability of the path.
    public let status: Status

    // MARK: - Lifecycle

    /// Creates a `ConnectivitySnapshot` instance given the provided parameter(s).
    ///
    /// - Parameters:
    ///   - status:    The usability of the path.
    ///   - interface: The kind of interface the path is using, if one is known. Default value is `nil`.
    ///   - changedAt: The moment `status` was last entered.
    public init(status: Status, interface: Interface? = nil, changedAt: ContinuousClock.Instant) {
        self.changedAt = changedAt
        self.interface = interface
        self.status = status
    }
}
