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

/// List of all possible error cases thrown when conversion from `Requestable` to `URLRequest` fails.
public enum RequestableError: Error, Sendable {
    /// Base URL failed validation. Most probable cause is invalid URL host.
    case invalidBaseURL

    /// `URLComponents` initialization with provided URL string failed.
    case invalidURL

    /// URL path failed validation.
    case invalidURLPath
}
