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

/// The `TokenCredential` type declares an object used by Atom in network requests that require bearer authentication.
public struct TokenCredential: Sendable {
    // MARK: - Properties

    /// The access token as defined in OAuth 2.0 spec.
    public let accessToken: String

    /// The expiration date of the access token.
    public let expiresAt: Date

    /// The refresh token as defined in OAuth 2.0 spec.
    public let refreshToken: String

    // MARK: - Lifecycle

    /// Creates a `TokenCredential` instance given the provided parameter(s).
    ///
    /// - Parameters:
    ///   - accessToken:  The access token as defined in OAuth 2.0 spec.
    ///   - expiresAt:    The expiration date of the access token.
    ///   - refreshToken: The refresh token as defined in OAuth 2.0 spec.
    public init(accessToken: String, expiresAt: Date, refreshToken: String) {
        self.accessToken = accessToken
        self.expiresAt = expiresAt
        self.refreshToken = refreshToken
    }
}
