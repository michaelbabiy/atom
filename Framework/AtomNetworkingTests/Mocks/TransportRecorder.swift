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
import Foundation

// MARK: - TransportRecorder

final class TransportRecorder: @unchecked Sendable {
    // MARK: - Properties

    /// The lock guarding the recorded values, since plugins are `Sendable` and may record from any isolation.
    private let lock: NSLock = .init()

    /// The error a plugin saw coming back from the transport.
    private var recordedError: AtomError?

    /// The response a plugin saw coming back from the transport.
    private var recordedResponse: AtomResponse?

    // MARK: - Computed Properties

    /// Returns the error a plugin saw coming back from the transport, if any.
    var error: AtomError? {
        lock.lock()

        defer { lock.unlock() }

        return recordedError
    }

    /// Returns the response a plugin saw coming back from the transport, if any.
    var response: AtomResponse? {
        lock.lock()

        defer { lock.unlock() }

        return recordedResponse
    }

    // MARK: - Functions

    /// Records the error a plugin saw coming back from the transport.
    ///
    /// - Parameters:
    ///   - error: The error to record.
    func record(error: AtomError) {
        lock.lock()

        defer { lock.unlock() }

        recordedError = error
    }

    /// Records the response a plugin saw coming back from the transport.
    ///
    /// - Parameters:
    ///   - response: The response to record.
    func record(response: AtomResponse) {
        lock.lock()

        defer { lock.unlock() }

        recordedResponse = response
    }
}
