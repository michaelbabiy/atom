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

// MARK: - Helper Properties and Methods

extension AtomError {
    /// Returns `Bool` indicating whether the error is due to an invalid or expired access token.
    public var isAuthorizationFailure: Bool {
        guard case let .response(response) = self else {
            return false
        }

        return response.statusCode == 401
    }

    /// Returns `Bool` indicating whether the error is a general "Bad Request" (HTTP 400) from a normal API response.
    ///
    /// This detects cases where an API endpoint returned a 400 status code, typically due to invalid parameters,
    /// malformed requests, or other client errors.
    public var isBadRequest: Bool {
        guard case let .response(response) = self else {
            return false
        }

        return response.statusCode == 400
    }

    /// Convenience variable for returning a `Bool` indicating whether the error is due to the device having no usable network path.
    ///
    /// This is `true` in both of the ways a request can be lost to being offline, whether a configured
    /// `ConnectivityPlugin` refused it before sending or `URLSession` failed it with
    /// `NSURLErrorNotConnectedToInternet`. Which of the two happens is a matter of timing rather than of
    /// anything the client did, so a client showing an offline state does not have to care.
    ///
    /// Matching `case .connectivity` does the same job and gives access to the reason.
    public var isOffline: Bool {
        guard case .connectivity = self else {
            return false
        }

        return true
    }

    /// Convenience method for decoding error object or message returned by the service.
    ///
    /// JSON decoder with the default formatting settings and decoding strategies will be used.
    ///
    /// - Parameters:
    ///   - type: The type to decode.
    ///
    /// - Returns: An optional instance of type `T` if `AtomError` is `.response`, and contains valid data, `nil` otherwise.
    public func decodeIfPresent<T: Decodable>(as type: T.Type) throws -> T? {
        guard case let .response(response) = self else {
            return nil
        }

        // Atom supports returning raw data without decoding when the error object structure in not known.
        guard let value = response.data as? T else {
            return try JSONDecoder().decode(type, from: response.data)
        }

        return value
    }
}

// MARK: - AtomError + StringConvertible

extension AtomError: StringConvertible {
    var stringValue: String {
        switch self {
        case .connectivity:
            return "connectivity"
        case .decoder:
            return "decoder"
        case .requestable:
            return "requestable"
        case .response:
            return "response"
        case .session:
            return "session"
        case .unexpected:
            return "unexpected"
        }
    }
}

// MARK: - AtomError + CustomStringConvertible

extension AtomError: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .connectivity(error):
            return "🧨 ConnectivityPlugin or URLSession could not establish a usable internet connection. 💥 Error: \(error)"
        case let .decoder(error):
            return "🧨 JSONDecoder failed to decode the response. This is usually due to a mismatch between the response and the expected type. 💥 Error: \(error)"
        case let .requestable(error):
            return "🧨 Atom failed to initialize a request. This is usually due to an invalid base URL or path. Double-check the Requestable implementation. 💥 Error: \(error)"
        case let .response(error):
            return "🧨 Atom received an invalid response that is not in the 200-299 range. 💥 Error: \(error)"
        case let .session(error):
            return "🧨 URLSession failed to resume a request due to an error. 💥 Error: \(error)"
        case .unexpected:
            return "🧨 Unexpected logic error. Please submit an issue on GitHub."
        }
    }
}
