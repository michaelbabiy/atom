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

// MARK: - Plugins

extension ServiceActor {
    /// Executes a request through the configured plugin chain.
    ///
    /// Starts with the normal request path and then wraps it with each plugin.
    /// Conceptually, this builds a chain where each plugin points to the next
    /// handler, with `deduplicatedResponse` at the end:
    ///
    /// `Plugin A → Plugin B → deduplicatedResponse`
    ///
    /// Plugins are added in reverse order so the first plugin in
    /// `ServiceConfiguration.plugins` is the first one to see the request.
    /// This means a plugin can handle or refuse a request before de-duplication,
    /// authorization, or token refresh happens.
    ///
    /// When no plugins are configured, the chain is just the normal request path.
    ///
    /// - Parameters:
    ///   - requestable: The request to execute.
    ///
    /// - Returns: The raw `AtomResponse`.
    /// - Throws: `AtomError` from a plugin that stops the chain, or from the underlying request.
    func pluggedResponse(for requestable: any Requestable) async throws(AtomError) -> AtomResponse {
        var current = NextHandler { requestable in
            try await self.deduplicatedResponse(for: requestable)
        }

        for plugin in serviceConfiguration.plugins.reversed() {
            let next = current

            current = NextHandler { requestable in
                try await plugin.send(requestable, next: next)
            }
        }

        return try await current(requestable)
    }
}
