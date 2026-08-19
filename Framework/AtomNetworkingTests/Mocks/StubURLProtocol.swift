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

// MARK: - StubURLProtocol

/// A transport that answers every request from a stubbed outcome, so nothing leaves the process.
final class StubURLProtocol: URLProtocol {
    // MARK: - Nested Types

    // MARK: - Outcome

    /// The reply a stubbed request is answered with.
    enum Outcome: Sendable {
        /// The transport fails the request with the given error.
        case failure(URLError)

        /// The transport answers the request with the given status code and body.
        case success(statusCode: Int, data: Data)
    }

    // MARK: - Static Properties

    /// The lock guarding the stubbed outcome and the count, since `URLSession` loads on its own queue.
    private static let lock: NSLock = .init()

    /// The number of requests that reached the transport since the stub was armed.
    private nonisolated(unsafe) static var count: Int = 0

    /// The outcome every request is answered with.
    private nonisolated(unsafe) static var stubbed: Outcome = .success(statusCode: 200, data: .init())

    // MARK: - Static Computed Properties

    /// Returns the outcome every request is answered with.
    static var outcome: Outcome {
        lock.lock()

        defer { lock.unlock() }

        return stubbed
    }

    /// Returns the number of requests that reached the transport since the stub was armed.
    static var requestCount: Int {
        lock.lock()

        defer { lock.unlock() }

        return count
    }

    /// Returns a session that routes every request to the stub.
    static var session: URLSession {
        let configuration: URLSessionConfiguration = .ephemeral

        configuration.protocolClasses = [StubURLProtocol.self]

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
        StubURLProtocol.recordRequest()

        switch StubURLProtocol.outcome {
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

    override func stopLoading() {}

    // MARK: - Static Functions

    /// Arms the stub with an outcome and clears the request count.
    ///
    /// - Parameters:
    ///   - outcome: The outcome every subsequent request is answered with.
    static func arm(with outcome: Outcome) {
        lock.lock()

        defer { lock.unlock() }

        count = 0
        stubbed = outcome
    }

    /// Records that a request reached the transport.
    static func recordRequest() {
        lock.lock()

        defer { lock.unlock() }

        count += 1
    }
}
