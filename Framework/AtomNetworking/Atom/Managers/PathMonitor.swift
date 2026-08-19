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
import Network

// MARK: - PathMonitor

/// A continuously running monitor of the device's network path, built on `NWPathMonitor`.
///
/// This is the default monitor for `ConnectivityPlugin`. It exists so that adopting connectivity does not
/// require every app to hand roll the same wrapper, and in particular so the `changedAt` stamp is handled in
/// one place.
///
/// Monitoring starts lazily on the first `snapshot` read rather than at initialization, so constructing a
/// plugin does not start a network agent subscription for an app that never sends a request. Until the first
/// path update arrives the status is `.unknown`, which never gates.
public actor PathMonitor: ConnectivityMonitoring {
    // MARK: - Nested Types

    // MARK: - PathUpdate

    /// A single path reading, reduced to `Sendable` values before it leaves the `NWPathMonitor` queue.
    struct PathUpdate: Sendable {
        /// The kind of interface the path is using, if one is known.
        let interface: ConnectivitySnapshot.Interface?

        /// The usability of the path.
        let status: ConnectivitySnapshot.Status
    }

    // MARK: - Properties

    /// The most recent reading, returned as is by `snapshot`.
    var current: ConnectivitySnapshot

    /// The monotonic clock used to stamp status transitions.
    private let clock: ContinuousClock

    /// The continuation feeding `updates`.
    private nonisolated let continuation: AsyncStream<PathUpdate>.Continuation

    /// A flag indicating whether `NWPathMonitor` has been started.
    private var isMonitoring: Bool

    /// The underlying system monitor.
    ///
    /// `nonisolated` so `deinit` can cancel it. `NWPathMonitor` is `Sendable` and safe to call from any
    /// thread, and the only calls made against it are `start(queue:)` once and `cancel()` on deallocation.
    private nonisolated let monitor: NWPathMonitor

    /// The queue `NWPathMonitor` delivers updates on.
    private let queue: DispatchQueue

    /// The stream of path readings drained by `startIfNeeded`.
    private nonisolated let updates: AsyncStream<PathUpdate>

    // MARK: - Computed Properties

    /// Returns the current reading of the device's network path, starting monitoring on first access.
    public var snapshot: ConnectivitySnapshot {
        get async {
            startIfNeeded()

            return current
        }
    }

    // MARK: - Lifecycle

    /// Creates a `PathMonitor` instance.
    public init() {
        let (updates, continuation) = AsyncStream<PathUpdate>.makeStream()

        self.clock = .init()
        self.continuation = continuation
        self.current = .init(status: .unknown, changedAt: clock.now)
        self.isMonitoring = false
        self.monitor = .init()
        self.queue = .init(label: "com.alaskaair.atom.path.monitor")
        self.updates = updates
    }

    /// Finishes the update stream and stops monitoring on deallocation, so the process leaks neither the
    /// draining task nor a network agent subscription.
    deinit {
        continuation.finish()
        monitor.cancel()
    }

    // MARK: - Functions

    /// Applies a path reading, stamping `changedAt` only when the status actually changes.
    ///
    /// - Parameters:
    ///   - update: The reading to apply.
    func apply(_ update: PathUpdate) {
        guard update.status != .unknown else {
            return
        }

        let interface = update.status == .unsatisfied || update.interface == .other ? current.interface : update.interface

        guard update.status != current.status else {
            current = .init(status: current.status, interface: interface, changedAt: current.changedAt)

            return
        }

        current = .init(status: update.status, interface: interface, changedAt: clock.now)
    }

    /// Starts `NWPathMonitor` and begins draining its updates, if it is not already running.
    private func startIfNeeded() {
        guard !isMonitoring else {
            return
        }

        isMonitoring = true

        monitor.pathUpdateHandler = { [continuation] path in
            continuation.yield(PathUpdate(interface: .init(path), status: .init(path.status)))
        }

        monitor.start(queue: queue)

        Task { [weak self, updates] in
            for await update in updates {
                await self?.apply(update)
            }
        }
    }
}
