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

// MARK: - TerminalPlugin

/// A plugin that short circuits by returning, so the chain never reaches the transport.
struct TerminalPlugin: AtomPlugin {
    // MARK: - Properties

    /// The recorder collecting events.
    let recorder: PluginRecorder

    // MARK: - Functions

    func send(_: any Requestable, next _: NextHandler) async throws(AtomError) -> AtomResponse {
        recorder.record("terminal")

        return .success
    }
}
