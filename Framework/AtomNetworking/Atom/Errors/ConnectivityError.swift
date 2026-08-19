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

// MARK: - ConnectivityError

/// The error describing a request that could not be sent because the device is offline.
///
/// This arrives as `AtomError.connectivity`, which is raised in two situations. A configured
/// `ConnectivityPlugin` refused the request before it was sent, or the transport failed with
/// `NSURLErrorNotConnectedToInternet`. Both read as offline to a client, so either one can be handled by
/// matching a single case rather than by inspecting error codes. This does not catch every offline failure.
/// Timeouts and DNS failures stay in `AtomError.session`.
///
/// ```swift
/// do {
///     let trips = try await atom.enqueue(TripsEndpoint()).resume(expecting: Trips.self)
/// } catch .connectivity {
///     presentOfflineBanner()
/// } catch {
///     presentGenericFailure()
/// }
/// ```
///
/// `reason` tells the two ways of being offline apart. Most clients can ignore it, since both mean the same
/// thing to a person looking at the screen. It matters when logging, because only one of the two is a decision
/// Atom made.
public struct ConnectivityError: Error, Sendable {
    // MARK: - Nested Types

    // MARK: - Reason

    /// How the offline condition was discovered.
    public enum Reason: Sendable, Equatable {
        /// `ConnectivityPlugin` refused the request before it was sent, because the path had stayed
        /// unsatisfied past the settling window.
        ///
        /// No request left the device, so nothing was retried, logged, or timed out at the transport.
        case gated

        /// `URLSession` reported that the request could not be sent because the device is not connected.
        ///
        /// The request was attempted. Atom reclassifies `NSURLErrorNotConnectedToInternet` here so that
        /// being offline reads the same whether or not a connectivity plugin is configured.
        case transport
    }

    // MARK: - Properties

    /// The kind of interface the path was using, if one was known.
    ///
    /// Only ever set for `.gated`, since `URLSession` does not report an interface with its error.
    public let interface: ConnectivitySnapshot.Interface?

    /// How the offline condition was discovered.
    public let reason: Reason

    /// The `URLSession` error this was reclassified from, when `reason` is `.transport`.
    public let underlyingError: Error?

    // MARK: - Lifecycle

    /// Creates a `ConnectivityError` instance given the provided parameter(s).
    ///
    /// - Parameters:
    ///   - reason:          How the offline condition was discovered.
    ///   - interface:       The kind of interface the path was using, if one was known. Default value is `nil`.
    ///   - underlyingError: The error this was reclassified from, if any. Default value is `nil`.
    public init(reason: Reason, interface: ConnectivitySnapshot.Interface? = nil, underlyingError: Error? = nil) {
        self.interface = interface
        self.reason = reason
        self.underlyingError = underlyingError
    }
}

// MARK: - CustomStringConvertible

extension ConnectivityError: CustomStringConvertible {
    public var description: String {
        var description =
            switch reason {
            case .gated:
                "🧨 Atom refused the request because the device has no usable network path."
            case .transport:
                "🧨 URLSession could not send the request because the device is not connected."
            }

        if let interface {
            description += " 📡 Last interface: \(interface)."
        }

        if let underlyingError {
            description += " 💥 Error: \(underlyingError)"
        }

        return description
    }
}
