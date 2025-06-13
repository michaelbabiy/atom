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
import os.log

// MARK: - Protocol Conformance

extension Interceptor: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        guard isEnabled else {
            return
        }

        // Create formatted log value.
        let logValue = "\(String(reflecting: task))\(String(reflecting: metrics))"

        // Log task using os_log.
        os_log(.info, log: log, "%@", logValue)
    }
}
