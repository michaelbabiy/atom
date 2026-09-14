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

// MARK: - ConnectivityPlugin

/// A plugin that refuses a request when the device has settled into having no usable network path.
///
/// ## Usage
/// ```swift
/// let atom = Atom(
///     serviceConfiguration: ServiceConfiguration(
///         plugins: [ConnectivityPlugin()]
///     )
/// )
/// ```
///
/// The refusal arrives as `AtomError.connectivity` carrying a `ConnectivityError` with a reason of `.gated`.
/// A client that only wants to know whether the device is offline does not have to distinguish it from a
/// transport level failure, since both arrive as the same case.
///
/// ## Why we don't simply check the network first?
/// A device being connected to Wi-Fi or cellular doesn't mean the request will actually work.
/// For example, a captive Wi-Fi portal or a VPN can show that the network is connected while requests still fail.
/// So the plugin only blocks a request when the system tells us there is no network route at all. If a route exists, we
/// let the request proceed and see what happens.
///
/// ## Why we wait before blocking
/// Network connections can briefly disappear when switching from Wi-Fi to cellular.
/// If we blocked the request immediately, we'd sometimes report that the device is offline when it's actually
/// just switching connections. So we wait until the network has been unavailable for settlingInterval before blocking the request.
///
/// Because plugins run outside de-duplication and authorization, a refusal here never wakes a token refresh.
public struct ConnectivityPlugin: AtomPlugin {
    // MARK: - Static Properties

    /// The default interval a path must stay unsatisfied before requests are refused.
    public static let defaultSettlingInterval: Duration = .seconds(3)

    // MARK: - Properties

    /// The monitor supplying path readings.
    let monitor: any ConnectivityMonitoring

    /// The interval a path must stay unsatisfied before requests are refused.
    let settlingInterval: Duration

    // MARK: - Lifecycle

    /// Creates a `ConnectivityPlugin` instance given the provided parameter(s).
    ///
    /// - Parameters:
    ///   - monitor:          The monitor supplying path readings. Default value is a new `PathMonitor`. Pass
    ///                       your own conforming type when the app already owns a monitor, so the process does
    ///                       not run two.
    ///   - settlingInterval: The interval a path must stay unsatisfied before requests are refused. Default
    ///                       value is `defaultSettlingInterval`.
    public init(monitor: any ConnectivityMonitoring = PathMonitor(), settlingInterval: Duration = ConnectivityPlugin.defaultSettlingInterval) {
        self.monitor = monitor
        self.settlingInterval = settlingInterval
    }

    // MARK: - Functions

    /// Refuses the request if the path has settled into being unsatisfied, otherwise passes it along.
    ///
    /// - Parameters:
    ///   - requestable: The request to handle.
    ///   - next:        The handler representing the rest of the pipeline.
    ///
    /// - Returns: The raw `AtomResponse`.
    /// - Throws:  `AtomError.connectivity` when the request is refused, or whatever the rest of the pipeline
    ///            throws.
    public func send(_ requestable: any Requestable, next: NextHandler) async throws(AtomError) -> AtomResponse {
        let snapshot = await monitor.snapshot

        guard snapshot.status == .unsatisfied, snapshot.changedAt.duration(to: ContinuousClock().now) >= settlingInterval else {
            return try await next(requestable)
        }

        throw .connectivity(ConnectivityError(reason: .gated, interface: snapshot.interface))
    }
}
