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

// MARK: - RefreshEndpoint

/// An endpoint that requires authorization, and tells a probe each time a caller asks whether it does.
///
/// Every instance resolves to the same host and path, and carries no header or query items, so the only header on
/// the resulting request is the one authorization applies. That keeps a test free to assert on the whole header
/// dictionary rather than picking one entry out of a crowd.
struct RefreshEndpoint: Requestable {
    // MARK: - Properties

    /// The probe notified each time a caller reaches the authorization decision for this request, if any.
    let probe: AuthorizationProbe?

    // MARK: - Computed Properties

    var requiresAuthorization: Bool {
        // Authorization reads this first, and then decides whether the stored credential needs refreshing without
        // suspending in between, so an arrival recorded here is a caller that has already made that decision.
        probe?.markArrived()

        return true
    }

    // MARK: - Lifecycle

    /// Creates a `RefreshEndpoint` instance given the provided parameter(s).
    ///
    /// - Parameters:
    ///   - probe: The probe notified each time a caller reaches the authorization decision. Defaults to `nil`.
    init(probe: AuthorizationProbe? = nil) {
        self.probe = probe
    }

    // MARK: - Functions

    func baseURL() throws(AtomError) -> BaseURL {
        try .init(host: "api.alaskaair.com")
    }

    func path() throws(AtomError) -> URLPath {
        try .init("/path")
    }
}
