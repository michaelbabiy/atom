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

/// The `ConnectivityMonitoring` protocol declares an interface for reporting the device's current network path.
///
/// Atom ships `PathMonitor`, which conforms to this protocol on top of `NWPathMonitor`, and
/// `ConnectivityPlugin` uses it by default. Conform your own type when the app already owns a monitor, so the
/// process does not end up running two of them:
///
/// ```swift
/// extension NetworkMonitorService: ConnectivityMonitoring {
///     var snapshot: ConnectivitySnapshot {
///         get async { ConnectivitySnapshot(status: isConnected ? .satisfied : .unsatisfied, changedAt: lastChange) }
///     }
/// }
///
/// let atom = Atom(
///     serviceConfiguration: ServiceConfiguration(
///         plugins: [ConnectivityPlugin(monitor: NetworkMonitorService.shared)]
///     )
/// )
/// ```
///
/// A conforming type is responsible for one detail that is easy to get wrong: `changedAt` must be stamped when
/// the *status* changes, not on every path update. See `ConnectivitySnapshot` for why.
public protocol ConnectivityMonitoring: Sendable {
    /// Returns the current reading of the device's network path.
    var snapshot: ConnectivitySnapshot { get async }
}
