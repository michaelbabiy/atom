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

// MARK: - GatedURLProtocol

/// A transport that holds every request open until a test releases it, so concurrent callers overlap on purpose.
///
/// `startLoading` never blocks its thread. An arriving request is counted and parked, and is answered only once
/// `release()` is called. Requests arriving after a release are answered immediately, so the same gate serves both
/// the overlapping and the sequential cases.
final class GatedURLProtocol: URLProtocol {
    // MARK: - Nested Types

    // MARK: - Outcome

    /// The reply a gated request is answered with.
    enum Outcome: Sendable {
        /// The transport fails the request with the given error.
        case failure(URLError)

        /// The transport answers the request with the given status code and body.
        case success(statusCode: Int, data: Data)
    }

    // MARK: - Static Properties

    /// The lock guarding the gate, the parked requests, and the count, since `URLSession` loads on its own queue.
    private static let lock: NSLock = .init()

    /// The number of requests that reached the transport since the gate was armed.
    private nonisolated(unsafe) static var count: Int = 0

    /// A flag indicating whether the gate is open, meaning arriving requests are answered rather than parked.
    private nonisolated(unsafe) static var isOpen: Bool = false

    /// The requests that arrived while the gate was closed and are still waiting to be answered.
    private nonisolated(unsafe) static var parked: [GatedURLProtocol] = .init()

    /// The outcome every request is answered with.
    private nonisolated(unsafe) static var stubbed: Outcome = .success(statusCode: 200, data: .init())

    // MARK: - Static Computed Properties

    /// Returns the outcome every request is answered with.
    static var outcome: Outcome {
        lock.lock()

        defer { lock.unlock() }

        return stubbed
    }

    /// Returns the number of requests that reached the transport since the gate was armed.
    static var requestCount: Int {
        lock.lock()

        defer { lock.unlock() }

        return count
    }

    /// Returns a session that routes every request to the gate.
    static var session: URLSession {
        let configuration: URLSessionConfiguration = .ephemeral

        configuration.protocolClasses = [GatedURLProtocol.self]

        return URLSession(configuration: configuration)
    }

    // MARK: - Overridden Functions

    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        GatedURLProtocol.lock.lock()

        GatedURLProtocol.count += 1

        let isAnsweredNow: Bool = GatedURLProtocol.isOpen

        if !isAnsweredNow {
            GatedURLProtocol.parked.append(self)
        }

        GatedURLProtocol.lock.unlock()

        if isAnsweredNow {
            answer()
        }
    }

    override func stopLoading() {}

    // MARK: - Static Functions

    /// Arms the gate with an outcome, closes it, and clears the request count along with any parked requests.
    ///
    /// - Parameters:
    ///   - outcome: The outcome every subsequent request is answered with.
    static func arm(with outcome: Outcome) {
        lock.lock()

        defer { lock.unlock() }

        count = 0
        isOpen = false
        parked = .init()
        stubbed = outcome
    }

    /// Opens the gate and answers every request parked behind it.
    ///
    /// Requests arriving after this call are answered without being parked.
    static func release() {
        lock.lock()

        isOpen = true

        let waiting: [GatedURLProtocol] = parked

        parked = .init()

        lock.unlock()

        waiting.forEach { $0.answer() }
    }

    // MARK: - Functions

    /// Answers this request with the armed outcome.
    private func answer() {
        switch GatedURLProtocol.outcome {
        case let .failure(error):
            client?.urlProtocol(self, didFailWithError: error)

        case let .success(statusCode, data):
            guard let url = request.url, let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil) else {
                client?.urlProtocol(self, didFailWithError: URLError(.badURL))

                return
            }

            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        }
    }
}
