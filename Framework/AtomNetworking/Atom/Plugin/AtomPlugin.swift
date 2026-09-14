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

// MARK: - AtomPlugin

/// A composable behavior wrapped around request execution.
///
/// Plugins run outside de-duplication and authorization, in the order they are passed to
/// `ServiceConfiguration(plugins:)`. The first element is outermost. Each plugin receives the request and a
/// `next` handler, and may:
///
/// - Inspect or replace the request before passing it on
/// - Short circuit by throwing without calling `next`
/// - Wrap or reclassify whatever `next` returns or throws
///
/// ## Usage
/// ```swift
/// struct LoggingPlugin: AtomPlugin {
///     func send(_ requestable: any Requestable, next: NextHandler) async throws(AtomError) -> AtomResponse {
///         try await next(requestable)
///     }
/// }
/// ```
public protocol AtomPlugin: Sendable {
    /// Handles a request, optionally passing it along to the rest of the pipeline.
    ///
    /// - Parameters:
    ///   - requestable: The request to handle.
    ///   - next:        The handler representing the rest of the pipeline.
    ///
    /// - Returns: The raw `AtomResponse`.
    /// - Throws:  `AtomError` if the plugin short circuits, or whatever `next` throws.
    func send(_ requestable: any Requestable, next: NextHandler) async throws(AtomError) -> AtomResponse
}

// MARK: - NextHandler

/// The handler a plugin calls to hand a request to the rest of the pipeline.
///
/// Calling this runs every remaining plugin, then de-duplication, authorization, and finally the transport. A
/// plugin that returns without calling it has short circuited the request.
///
/// This is a type rather than a closure alias on purpose. Typed throws in a *function type* requires iOS 18
/// runtime support, and the library targets iOS 17. Wrapping an untyped closure and restoring the typed
/// error at the call boundary keeps `throws(AtomError)` on the API without raising the deployment target, the
/// same trick `Task.typedValue()` and `withAtomCheckedContinuation` already use.
public struct NextHandler: Sendable {
    // MARK: - Properties

    /// The wrapped pipeline continuation.
    private let handler: @Sendable (any Requestable) async throws -> AtomResponse

    // MARK: - Lifecycle

    /// Creates a `NextHandler` given the provided parameter(s).
    ///
    /// - Parameters:
    ///   - handler: The work representing the rest of the pipeline.
    public init(_ handler: @escaping @Sendable (any Requestable) async throws -> AtomResponse) {
        self.handler = handler
    }

    // MARK: - Functions

    /// Passes the request to the rest of the pipeline.
    ///
    /// - Parameters:
    ///   - requestable: The request to pass along.
    ///
    /// - Returns: The raw `AtomResponse`.
    /// - Throws:  `AtomError`, mapped from any underlying error.
    public func callAsFunction(_ requestable: any Requestable) async throws(AtomError) -> AtomResponse {
        do {
            return try await handler(requestable)
        } catch {
            throw (error as? AtomError) ?? .unexpected
        }
    }
}
