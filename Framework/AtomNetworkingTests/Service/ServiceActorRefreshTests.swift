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

// MARK: - ServiceActorRefreshTests

/// Covers the bearer refresh path, from the decision to refresh through to the header the request goes out with.
///
/// These tests call `applyAuthorizationHeader(to:)` rather than going through `resume(for:)`. The refresh call is
/// then the only request that reaches the transport, so the transport's request count is the refresh count and
/// nothing else. Going through `resume` would put the request being authorized on the same counter and leave every
/// "refreshed once" assertion needing arithmetic to interpret.
final class ServiceActorRefreshTests: XCTestCase {
    // MARK: - Static Properties

    /// The body the authorization server answers a successful refresh with.
    ///
    /// `expires_in` rather than `expires_at`, which is the shape a service returns and the shape that leaves the
    /// refreshed credential comfortably unexpired without depending on how a date is formatted.
    private static let refreshedTokenData: Data = .init(
        "{\"access_token\":\"refreshed\",\"expires_in\":3600,\"refresh_token\":\"refreshed-refresh\"}".utf8
    )

    // MARK: - Functions

    func testAValidCredentialIsAppliedWithoutContactingTheAuthorizationEndpoint() async throws {
        // Given
        let writable: StoringTokenCredentialWritable = .init(credential: .init(accessToken: "valid", expiresAt: .distantFuture, refreshToken: "refresh"))

        GatedURLProtocol.arm(with: .success(statusCode: 200, data: Self.refreshedTokenData))
        GatedURLProtocol.release()

        let serviceActor: ServiceActor = try makeServiceActor(writable: writable)

        // When
        let authorized: any Requestable = try await serviceActor.applyAuthorizationHeader(to: RefreshEndpoint())
        let request: URLRequest = try .init(requestable: authorized)

        // Then
        XCTAssertEqual(GatedURLProtocol.requestCount, 0)
        XCTAssertEqual(writable.writeCount, 0)
        XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer valid")
    }

    func testAnExpiredCredentialIsRefreshedOnceBeforeTheRequestIsAuthorized() async throws {
        // Given
        let writable: StoringTokenCredentialWritable = .init(credential: .init(accessToken: "expired", expiresAt: .distantPast, refreshToken: "refresh"))

        GatedURLProtocol.arm(with: .success(statusCode: 200, data: Self.refreshedTokenData))
        GatedURLProtocol.release()

        let serviceActor: ServiceActor = try makeServiceActor(writable: writable)

        // When
        _ = try await serviceActor.applyAuthorizationHeader(to: RefreshEndpoint())

        // Then
        XCTAssertEqual(GatedURLProtocol.requestCount, 1)
    }

    func testTheRefreshedCredentialIsStoredThroughTheWritable() async throws {
        // Given
        let writable: StoringTokenCredentialWritable = .init(credential: .init(accessToken: "expired", expiresAt: .distantPast, refreshToken: "refresh"))

        GatedURLProtocol.arm(with: .success(statusCode: 200, data: Self.refreshedTokenData))
        GatedURLProtocol.release()

        let serviceActor: ServiceActor = try makeServiceActor(writable: writable)

        // When
        _ = try await serviceActor.applyAuthorizationHeader(to: RefreshEndpoint())

        // Then
        XCTAssertEqual(writable.writeCount, 1)
        XCTAssertEqual(writable.storedCredential.accessToken, "refreshed")
        XCTAssertEqual(writable.storedCredential.refreshToken, "refreshed-refresh")
        XCTAssertFalse(writable.storedCredential.requiresRefresh)
    }

    func testTheRefreshedAccessTokenReachesTheOutgoingAuthorizationHeader() async throws {
        // Given
        let writable: StoringTokenCredentialWritable = .init(credential: .init(accessToken: "expired", expiresAt: .distantPast, refreshToken: "refresh"))

        GatedURLProtocol.arm(with: .success(statusCode: 200, data: Self.refreshedTokenData))
        GatedURLProtocol.release()

        let serviceActor: ServiceActor = try makeServiceActor(writable: writable)

        // When
        //
        // This is the value the actor hands straight to `session.data(for:)`, and `URLRequest(requestable:)` is the
        // initializer that call uses, so the header asserted on here is the header that goes out.
        let authorized: any Requestable = try await serviceActor.applyAuthorizationHeader(to: RefreshEndpoint())
        let request: URLRequest = try .init(requestable: authorized)

        // Then
        XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer refreshed")
    }

    func testCallersArrivingAcrossTheRefreshBoundaryShareASingleRefresh() async throws {
        // Given
        //
        // The arrangement is the point of this test. A crowd of callers that all arrive before the refresh starts
        // proves nothing, because they all queue behind the same in-flight task and there is no second decision to
        // get wrong. The failure being guarded against is a caller arriving in the window between the refresh task
        // clearing itself and the refreshed credential landing in the store, seeing an expired credential with no
        // refresh in progress, and spending a refresh token that has already been used.
        //
        // So callers arrive on both sides of that moment: a first wave waits for the refresh to be in flight, then a
        // second wave trickles in while the gate opens partway through it.
        let probe: AuthorizationProbe = .init()
        let writable: StoringTokenCredentialWritable = .init(credential: .init(accessToken: "expired", expiresAt: .distantPast, refreshToken: "refresh"))

        GatedURLProtocol.arm(with: .success(statusCode: 200, data: Self.refreshedTokenData))

        let serviceActor: ServiceActor = try makeServiceActor(writable: writable)

        // When
        var callers: [Task<Void, Error>] = .init()

        for _ in 0 ..< 8 {
            callers.append(Task {
                _ = try await serviceActor.applyAuthorizationHeader(to: RefreshEndpoint(probe: probe))
            })
        }

        await wait(until: { probe.arrivals == 8 }, for: "the first wave to reach the authorization decision")
        await wait(until: { GatedURLProtocol.requestCount == 1 }, for: "the refresh to reach the transport")

        for index in 0 ..< 60 {
            // The gate opens partway into the second wave, so the callers still to come arrive while the refresh is
            // completing rather than safely after it.
            if index == 8 {
                GatedURLProtocol.release()
            }

            callers.append(Task {
                _ = try await serviceActor.applyAuthorizationHeader(to: RefreshEndpoint(probe: probe))
            })

            await Task.yield()
        }

        for caller in callers {
            try await caller.value
        }

        // Then
        XCTAssertEqual(GatedURLProtocol.requestCount, 1)
        XCTAssertEqual(writable.writeCount, 1)
        XCTAssertEqual(probe.arrivals, 68)
        XCTAssertEqual(writable.storedCredential.accessToken, "refreshed")
    }

    func testAFailedRefreshPropagatesToEveryWaitingCaller() async throws {
        // Given
        let probe: AuthorizationProbe = .init()
        let writable: StoringTokenCredentialWritable = .init(credential: .init(accessToken: "expired", expiresAt: .distantPast, refreshToken: "refresh"))

        GatedURLProtocol.arm(with: .failure(URLError(.timedOut)))

        let serviceActor: ServiceActor = try makeServiceActor(writable: writable)

        // When
        var callers: [Task<Void, Error>] = .init()

        for _ in 0 ..< 4 {
            callers.append(Task {
                _ = try await serviceActor.applyAuthorizationHeader(to: RefreshEndpoint(probe: probe))
            })
        }

        await wait(until: { probe.arrivals == 4 }, for: "every caller to reach the authorization decision")
        await wait(until: { GatedURLProtocol.requestCount == 1 }, for: "the refresh to reach the transport")

        GatedURLProtocol.release()

        var thrownErrors: [String] = .init()

        for caller in callers {
            do {
                try await caller.value
            } catch {
                thrownErrors.append((error as? AtomError)?.stringValue ?? "unknown")
            }
        }

        // Then
        XCTAssertEqual(GatedURLProtocol.requestCount, 1)
        XCTAssertEqual(thrownErrors, ["session", "session", "session", "session"])
        XCTAssertEqual(writable.writeCount, 0)
    }

    func testTheRefreshTaskIsClearedAfterARefreshSucceeds() async throws {
        // Given
        let writable: StoringTokenCredentialWritable = .init(credential: .init(accessToken: "expired", expiresAt: .distantPast, refreshToken: "refresh"))

        GatedURLProtocol.arm(with: .success(statusCode: 200, data: Self.refreshedTokenData))
        GatedURLProtocol.release()

        let serviceActor: ServiceActor = try makeServiceActor(writable: writable)

        // When
        _ = try await serviceActor.applyAuthorizationHeader(to: RefreshEndpoint())

        // Then
        let hasRefreshTask: Bool = await serviceActor.refreshTask != nil

        XCTAssertFalse(hasRefreshTask)
    }

    func testTheRefreshTaskIsClearedAfterARefreshFails() async throws {
        // Given
        let writable: StoringTokenCredentialWritable = .init(credential: .init(accessToken: "expired", expiresAt: .distantPast, refreshToken: "refresh"))

        GatedURLProtocol.arm(with: .failure(URLError(.timedOut)))
        GatedURLProtocol.release()

        let serviceActor: ServiceActor = try makeServiceActor(writable: writable)

        // When
        do {
            _ = try await serviceActor.applyAuthorizationHeader(to: RefreshEndpoint())
        } catch {
            // The failure is the arrangement here. What it leaves behind is what this test is about.
        }

        // Then
        let hasRefreshTask: Bool = await serviceActor.refreshTask != nil

        XCTAssertFalse(hasRefreshTask)
    }

    func testAStillExpiredCredentialRefreshesAgainAfterAnEarlierRefreshFailed() async throws {
        // Given
        //
        // A refresh task left behind by a failure would strand every later caller on a task that already threw, so
        // the second call reaching the transport at all is the behaviour worth pinning.
        let writable: StoringTokenCredentialWritable = .init(credential: .init(accessToken: "expired", expiresAt: .distantPast, refreshToken: "refresh"))

        GatedURLProtocol.arm(with: .failure(URLError(.timedOut)))
        GatedURLProtocol.release()

        let serviceActor: ServiceActor = try makeServiceActor(writable: writable)

        // When
        var firstError: AtomError?

        do {
            _ = try await serviceActor.applyAuthorizationHeader(to: RefreshEndpoint())
        } catch {
            firstError = error
        }

        GatedURLProtocol.arm(with: .success(statusCode: 200, data: Self.refreshedTokenData))
        GatedURLProtocol.release()

        _ = try await serviceActor.applyAuthorizationHeader(to: RefreshEndpoint())

        // Then
        XCTAssertEqual(firstError?.stringValue, "session")
        XCTAssertEqual(GatedURLProtocol.requestCount, 1)
        XCTAssertEqual(writable.storedCredential.accessToken, "refreshed")
    }

    func testABadRequestFromTheAuthorizationEndpointPostsDidFailToRefreshAccessToken() async throws {
        // Given
        let recorder: NotificationRecorder = .init()
        let writable: StoringTokenCredentialWritable = .init(credential: .init(accessToken: "expired", expiresAt: .distantPast, refreshToken: "refresh"))

        GatedURLProtocol.arm(with: .success(statusCode: 400, data: .init()))
        GatedURLProtocol.release()

        let serviceActor: ServiceActor = try makeServiceActor(writable: writable)

        // When
        var thrownError: AtomError?

        do {
            _ = try await serviceActor.applyAuthorizationHeader(to: RefreshEndpoint())
        } catch {
            thrownError = error
        }

        // Then
        XCTAssertEqual(thrownError?.stringValue, "response")
        XCTAssertEqual(recorder.refreshFailureCount, 1)
        XCTAssertEqual(recorder.authorizationFailureCount, 0)
    }

    func testAnUnauthorizedFromTheAuthorizationEndpointPostsDidFailToAuthorizeRequest() async throws {
        // Given
        //
        // This pins what the library does today, not what it arguably should. A 401 from the authorization server is
        // a refresh that failed, but only a 400 takes the refresh branch, so a 401 falls through to the branch meant
        // for a request that was refused. That asymmetry is logged separately as a bug; changing it here would leave
        // the change unpinned either way.
        let recorder: NotificationRecorder = .init()
        let writable: StoringTokenCredentialWritable = .init(credential: .init(accessToken: "expired", expiresAt: .distantPast, refreshToken: "refresh"))

        GatedURLProtocol.arm(with: .success(statusCode: 401, data: .init()))
        GatedURLProtocol.release()

        let serviceActor: ServiceActor = try makeServiceActor(writable: writable)

        // When
        var thrownError: AtomError?

        do {
            _ = try await serviceActor.applyAuthorizationHeader(to: RefreshEndpoint())
        } catch {
            thrownError = error
        }

        // Then
        XCTAssertEqual(thrownError?.stringValue, "response")
        XCTAssertEqual(recorder.refreshFailureCount, 0)
        XCTAssertEqual(recorder.authorizationFailureCount, 1)
    }

    func testAServerErrorFromTheAuthorizationEndpointPostsNoNotification() async throws {
        // Given
        //
        // Also current behaviour rather than intended behaviour. A refresh lost to a failing authorization server
        // tells a client nothing at all, which is the same asymmetry seen from the other side.
        let recorder: NotificationRecorder = .init()
        let writable: StoringTokenCredentialWritable = .init(credential: .init(accessToken: "expired", expiresAt: .distantPast, refreshToken: "refresh"))

        GatedURLProtocol.arm(with: .success(statusCode: 500, data: .init()))
        GatedURLProtocol.release()

        let serviceActor: ServiceActor = try makeServiceActor(writable: writable)

        // When
        var thrownError: AtomError?

        do {
            _ = try await serviceActor.applyAuthorizationHeader(to: RefreshEndpoint())
        } catch {
            thrownError = error
        }

        // Then
        XCTAssertEqual(thrownError?.stringValue, "response")
        XCTAssertEqual(recorder.refreshFailureCount, 0)
        XCTAssertEqual(recorder.authorizationFailureCount, 0)
    }

    /// Returns an actor configured for bearer authentication against the gated transport.
    ///
    /// - Parameters:
    ///   - writable: The credential store the actor reads from and refreshes into.
    ///
    /// - Returns: A `ServiceActor` whose every request, refresh included, reaches the gate.
    private func makeServiceActor(writable: any TokenCredentialWritable) throws -> ServiceActor {
        let authorizationEndpoint: AuthorizationEndpoint = try .init(host: "auth.alaskaair.com", path: "/token")
        let clientCredential: ClientCredential = .init(id: "identifier", secret: "secret")
        let authenticationMethod: AuthenticationMethod = .bearer(authorizationEndpoint, clientCredential, writable)
        let serviceConfiguration: ServiceConfiguration = .init(authenticationMethod: authenticationMethod)

        return .init(serviceConfiguration: serviceConfiguration, session: GatedURLProtocol.session)
    }

    /// Waits until a condition holds, failing the test rather than hanging the suite if it never does.
    ///
    /// The condition is the signal. The interval between checks only keeps the poll from spinning, and the deadline
    /// only turns a broken expectation into a failure, so no test here waits a guessed interval for work to happen.
    ///
    /// - Parameters:
    ///   - condition:   The condition to poll.
    ///   - description: A description of what is being waited on, used in the failure message.
    ///   - file:        The file the wait was requested from.
    ///   - line:        The line the wait was requested from.
    private func wait(
        until condition: @Sendable () -> Bool,
        for description: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline: Date = .init(timeIntervalSinceNow: 5)

        while Date() < deadline {
            if condition() {
                return
            }

            try? await Task.sleep(nanoseconds: 1_000_000)
        }

        XCTFail("Timed out waiting for \(description).", file: file, line: line)
    }
}
