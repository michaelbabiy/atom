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

/// List of all possible error cases thrown by `Atom` framework.
public enum AtomError: Error, Sendable {
    /// The request could not be sent because the device is offline.
    ///
    /// This is raised in two situations. A configured `ConnectivityPlugin` refused the request before it was
    /// sent, or the transport failed with `NSURLErrorNotConnectedToInternet`. `ConnectivityError.reason` tells
    /// the two apart.
    ///
    /// Those are the only two situations Atom can attribute to being offline with confidence. Other failures
    /// can also mean the network was unreachable, a DNS failure or a timeout for example, and those stay in
    /// `.session`.
    ///
    /// For more information, see `ConnectivityError`.
    case connectivity(ConnectivityError)

    /// Decoder failed to decode data.
    case decoder(DecodingError)

    /// Failed to initialize `URLRequest` with `Requestable` instance.
    case requestable(RequestableError)

    /// Service returned invalid response where the status code is not in `200...299` range.
    ///
    /// An optional response `data` will be set for further processing of the `body`. In the
    /// context of ACE Group, `data` will contain the error message or the model object.
    ///
    /// For more information, see `AtomResponse`.
    case response(AtomResponse)

    /// URLSession failed with error.
    ///
    /// Note: Only `NSURLErrorNotConnectedToInternet` is reclassified as `.connectivity`. Other transport
    /// failures stay here, including timeouts and DNS failures, and any of those can also mean the device
    /// was offline.
    case session(Error)

    /// Unexpected, logic error.
    case unexpected
}
