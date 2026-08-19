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
import XCTest

// MARK: - ServiceActorPluginsTests

final class ServiceActorPluginsTests: XCTestCase {
    func testPluggedResponseRunsPluginsOutermostFirstAndUnwindsInReverse() async throws {
        // Given
        let recorder: PluginRecorder = .init()
        let serviceConfiguration: ServiceConfiguration = .init(plugins: [
            RecordingPlugin(name: "outer", recorder: recorder),
            RecordingPlugin(name: "inner", recorder: recorder),
            TerminalPlugin(recorder: recorder)
        ])
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration)

        // When
        let response: AtomResponse = try await serviceActor.pluggedResponse(for: PluginsEndpoint())

        // Then
        XCTAssertEqual(recorder.events, ["outer.enter", "inner.enter", "terminal", "inner.exit", "outer.exit"])
        XCTAssertEqual(response.statusCode, 200)
    }

    func testPluggedResponseSkipsPluginsInsideOneThatRefuses() async {
        // Given
        let recorder: PluginRecorder = .init()
        let serviceConfiguration: ServiceConfiguration = .init(plugins: [
            RecordingPlugin(name: "outer", recorder: recorder),
            RefusingPlugin(recorder: recorder),
            RecordingPlugin(name: "inner", recorder: recorder)
        ])
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration)

        // When
        var thrownError: AtomError?
        var reason: ConnectivityError.Reason?

        do {
            _ = try await serviceActor.pluggedResponse(for: PluginsEndpoint())
        } catch {
            thrownError = error

            if case let .connectivity(connectivityError) = error {
                reason = connectivityError.reason
            }
        }

        // Then
        XCTAssertEqual(recorder.events, ["outer.enter", "refusing"])
        XCTAssertEqual(thrownError?.stringValue, "connectivity")
        XCTAssertEqual(reason, .gated)
    }

    func testPluggedResponseWithoutPluginsPassesTheRequestStraightThrough() async {
        // Given
        let serviceConfiguration: ServiceConfiguration = .init(plugins: [])
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration)

        // When
        var thrownError: AtomError?
        var requestableReason: String?

        do {
            _ = try await serviceActor.pluggedResponse(for: SentinelEndpoint())
        } catch {
            thrownError = error

            if case let .requestable(requestableError) = error {
                requestableReason = "\(requestableError)"
            }
        }

        // Then
        XCTAssertEqual(thrownError?.stringValue, "requestable")
        XCTAssertEqual(requestableReason, "invalidBaseURL")
    }
}
