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

// MARK: - DeduplicationEndpoint

/// An endpoint whose method, query items, header items, and de-duplication opt-in are set per test.
///
/// Every instance resolves to the same host and path, so two instances differ as a de-duplication key only where a
/// test makes them differ.
struct DeduplicationEndpoint: Requestable {
    // MARK: - Properties

    /// A flag indicating whether the library may coalesce identical concurrent executions of this request.
    let allowsDeduplication: Bool

    /// The array of header items to apply to a `URLRequest`.
    let headerItems: [HeaderItem]?

    /// The HTTP method to apply to a `URLRequest`.
    let method: HTTPMethod

    /// The array of query items to apply to a URL.
    let queryItems: [QueryItem]?

    /// The probe notified each time this request is resolved into a de-duplication key, if any.
    let probe: KeyDerivationProbe?

    // MARK: - Lifecycle

    /// Creates a `DeduplicationEndpoint` instance given the provided parameter(s).
    ///
    /// - Parameters:
    ///   - allowsDeduplication: A flag indicating whether the library may coalesce this request. Defaults to `true`.
    ///   - headerItems:         The array of header items to apply to a `URLRequest`. Defaults to `nil`.
    ///   - method:              The HTTP method to apply to a `URLRequest`. Defaults to `.get`.
    ///   - queryItems:          The array of query items to apply to a URL. Defaults to `nil`.
    ///   - probe:               The probe notified each time this request is keyed. Defaults to `nil`.
    init(
        allowsDeduplication: Bool = true,
        headerItems: [HeaderItem]? = nil,
        method: HTTPMethod = .get,
        queryItems: [QueryItem]? = nil,
        probe: KeyDerivationProbe? = nil
    ) {
        self.allowsDeduplication = allowsDeduplication
        self.headerItems = headerItems
        self.method = method
        self.queryItems = queryItems
        self.probe = probe
    }

    // MARK: - Functions

    func baseURL() throws(AtomError) -> BaseURL {
        try .init(host: "api.alaskaair.com")
    }

    func path() throws(AtomError) -> URLPath {
        // The path resolves while the actor derives the request key, synchronously and just before the lookup.
        probe?.markDerived()

        return try .init("/path")
    }
}
