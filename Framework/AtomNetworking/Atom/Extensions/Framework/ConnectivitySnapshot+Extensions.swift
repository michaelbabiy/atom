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
import Network

// MARK: - ConnectivitySnapshot.Status + NWPath.Status

extension ConnectivitySnapshot.Status {
    /// Creates a `ConnectivitySnapshot.Status` instance given the provided parameter(s).
    ///
    /// - Parameters:
    ///   - status: The `NWPath` status to convert.
    init(_ status: NWPath.Status) {
        switch status {
        case .satisfied:
            self = .satisfied
        case .unsatisfied:
            self = .unsatisfied
        case .requiresConnection:
            self = .satisfied
        @unknown default:
            self = .unknown
        }
    }
}

// MARK: - ConnectivitySnapshot.Interface + NWPath

extension ConnectivitySnapshot.Interface {
    /// Creates a `ConnectivitySnapshot.Interface` instance given the provided parameter(s).
    ///
    /// - Parameters:
    ///   - path: The `NWPath` to classify.
    init(_ path: NWPath) {
        self.init(usesInterfaceType: path.usesInterfaceType)
    }

    /// Creates a `ConnectivitySnapshot.Interface` instance given the provided parameter(s).
    ///
    /// - Parameters:
    ///   - usesInterfaceType: A closure reporting whether the path being classified uses the given interface type.
    init(usesInterfaceType: (NWInterface.InterfaceType) -> Bool) {
        if usesInterfaceType(.wifi) {
            self = .wifi
        } else if usesInterfaceType(.cellular) {
            self = .cellular
        } else if usesInterfaceType(.wiredEthernet) {
            self = .wired
        } else {
            self = .other
        }
    }
}
