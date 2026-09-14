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

// MARK: - ServiceActorTransportTests

final class ServiceActorTransportTests: XCTestCase {
    func testSuccessfulResponseReachesAPluginAndFlowsBackOutUnchanged() async throws {
        // Given
        let body: Data = .init("{\"value\":\"atom\"}".utf8)
        let recorder: TransportRecorder = .init()

        StubURLProtocol.arm(with: .success(statusCode: 200, data: body))

        let serviceConfiguration: ServiceConfiguration = .init(plugins: [ObservingPlugin(recorder: recorder)])
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration, session: StubURLProtocol.session)

        // When
        let response: AtomResponse = try await serviceActor.resume(for: TransportEndpoint())

        // Then
        XCTAssertEqual(StubURLProtocol.requestCount, 1)
        XCTAssertEqual(recorder.response?.statusCode, 200)
        XCTAssertEqual(recorder.response?.data, body)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.data, body)
    }

    func testNotConnectedToInternetSurfacesAsConnectivityWithATransportReason() async {
        // Given
        StubURLProtocol.arm(with: .failure(URLError(.notConnectedToInternet)))

        let serviceConfiguration: ServiceConfiguration = .init()
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration, session: StubURLProtocol.session)

        // When
        var thrownError: AtomError?
        var reason: ConnectivityError.Reason?
        var underlyingCode: Int?

        do {
            _ = try await serviceActor.resume(for: TransportEndpoint())
        } catch {
            thrownError = error

            if case let .connectivity(connectivityError) = error {
                reason = connectivityError.reason

                if let urlError = connectivityError.underlyingError as? URLError {
                    underlyingCode = urlError.errorCode
                }
            }
        }

        // Then
        XCTAssertEqual(StubURLProtocol.requestCount, 1)
        XCTAssertEqual(thrownError?.stringValue, "connectivity")
        XCTAssertEqual(reason, .transport)
        XCTAssertEqual(underlyingCode, NSURLErrorNotConnectedToInternet)
    }

    func testTimedOutStaysASessionErrorAndAPluginCanReclassifyIt() async {
        // Given
        let recorder: TransportRecorder = .init()

        StubURLProtocol.arm(with: .failure(URLError(.timedOut)))

        let serviceConfiguration: ServiceConfiguration = .init(plugins: [ReclassifyingPlugin(recorder: recorder)])
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration, session: StubURLProtocol.session)

        // When
        var thrownError: AtomError?

        do {
            _ = try await serviceActor.resume(for: TransportEndpoint())
        } catch {
            thrownError = error
        }

        // Then
        XCTAssertEqual(StubURLProtocol.requestCount, 1)
        XCTAssertEqual(recorder.error?.stringValue, "session")
        XCTAssertEqual(thrownError?.stringValue, "unexpected")
    }

    func testNonSuccessStatusCodeSurfacesAsResponseCarryingTheBody() async {
        // Given
        let body: Data = .init("{\"message\":\"boom\"}".utf8)

        StubURLProtocol.arm(with: .success(statusCode: 500, data: body))

        let serviceConfiguration: ServiceConfiguration = .init()
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration, session: StubURLProtocol.session)

        // When
        var thrownError: AtomError?
        var atomResponse: AtomResponse?

        do {
            _ = try await serviceActor.resume(for: TransportEndpoint())
        } catch {
            thrownError = error

            if case let .response(response) = error {
                atomResponse = response
            }
        }

        // Then
        XCTAssertEqual(StubURLProtocol.requestCount, 1)
        XCTAssertEqual(thrownError?.stringValue, "response")
        XCTAssertEqual(atomResponse?.statusCode, 500)
        XCTAssertEqual(atomResponse?.data, body)
    }

    func testRefusingPluginKeepsAnAuthenticatedRequestFromReachingTheTransport() async throws {
        // Given
        let authorizationEndpoint: AuthorizationEndpoint = try .init(host: "auth.alaskaair.com", path: "/token")
        let clientCredential: ClientCredential = .init(id: "identifier", secret: "secret")
        let authenticationMethod: AuthenticationMethod = .bearer(authorizationEndpoint, clientCredential, StubTokenCredentialWritable())

        StubURLProtocol.arm(with: .success(statusCode: 200, data: .init()))

        let serviceConfiguration: ServiceConfiguration = .init(authenticationMethod: authenticationMethod, plugins: [TransportRefusingPlugin()])
        let serviceActor: ServiceActor = .init(serviceConfiguration: serviceConfiguration, session: StubURLProtocol.session)

        // When
        var thrownError: AtomError?
        var reason: ConnectivityError.Reason?

        do {
            _ = try await serviceActor.resume(for: TransportEndpoint())
        } catch {
            thrownError = error

            if case let .connectivity(connectivityError) = error {
                reason = connectivityError.reason
            }
        }

        // Then
        XCTAssertEqual(StubURLProtocol.requestCount, 0)
        XCTAssertEqual(thrownError?.stringValue, "connectivity")
        XCTAssertEqual(reason, .gated)
    }
}
