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
import Network
import XCTest

final class PathMonitorTests: XCTestCase {
    func testApplyIgnoresUnknownStatusUpdate() async {
        // Given
        let monitor: PathMonitor = .init()
        let update: PathMonitor.PathUpdate = .init(interface: .wifi, status: .unknown)
        let changedAt = await monitor.current.changedAt

        // When
        await monitor.apply(update)

        let snapshot = await monitor.current

        // Then
        XCTAssertEqual(snapshot.status, .unknown)
        XCTAssertNil(snapshot.interface)
        XCTAssertEqual(snapshot.changedAt, changedAt)
    }

    func testApplyStampsChangedAtOnFirstSatisfiedUpdate() async {
        // Given
        let monitor: PathMonitor = .init()
        let update: PathMonitor.PathUpdate = .init(interface: .wifi, status: .satisfied)
        let changedAt = await monitor.current.changedAt

        // When
        await monitor.apply(update)

        let snapshot = await monitor.current

        // Then
        XCTAssertEqual(snapshot.status, .satisfied)
        XCTAssertEqual(snapshot.interface, .wifi)
        XCTAssertTrue(snapshot.changedAt > changedAt)
    }

    func testApplyRefreshesInterfaceWithoutRestampingOnSameStatus() async {
        // Given
        let monitor: PathMonitor = .init()
        let wifi: PathMonitor.PathUpdate = .init(interface: .wifi, status: .satisfied)
        let cellular: PathMonitor.PathUpdate = .init(interface: .cellular, status: .satisfied)

        // When
        await monitor.apply(wifi)

        let changedAt = await monitor.current.changedAt

        await monitor.apply(cellular)

        let snapshot = await monitor.current

        // Then
        XCTAssertEqual(snapshot.status, .satisfied)
        XCTAssertEqual(snapshot.interface, .cellular)
        XCTAssertEqual(snapshot.changedAt, changedAt)
    }

    func testApplyRestampsChangedAtOnStatusTransition() async {
        // Given
        let monitor: PathMonitor = .init()
        let satisfied: PathMonitor.PathUpdate = .init(interface: .wifi, status: .satisfied)
        let unsatisfied: PathMonitor.PathUpdate = .init(interface: .wifi, status: .unsatisfied)

        // When
        await monitor.apply(satisfied)

        let changedAt = await monitor.current.changedAt

        await monitor.apply(unsatisfied)

        let snapshot = await monitor.current

        // Then
        XCTAssertEqual(snapshot.status, .unsatisfied)
        XCTAssertTrue(snapshot.changedAt > changedAt)
    }

    func testApplyPreservesKnownInterfaceOnUnsatisfiedUpdate() async {
        // Given
        let monitor: PathMonitor = .init()
        let satisfied: PathMonitor.PathUpdate = .init(interface: .wifi, status: .satisfied)
        let unsatisfied: PathMonitor.PathUpdate = .init(interface: nil, status: .unsatisfied)

        // When
        await monitor.apply(satisfied)
        await monitor.apply(unsatisfied)

        let snapshot = await monitor.current

        // Then
        XCTAssertEqual(snapshot.status, .unsatisfied)
        XCTAssertEqual(snapshot.interface, .wifi)
    }

    func testApplyPreservesKnownInterfaceOnOtherInterfaceUpdate() async {
        // Given
        let monitor: PathMonitor = .init()
        let wifi: PathMonitor.PathUpdate = .init(interface: .wifi, status: .satisfied)
        let other: PathMonitor.PathUpdate = .init(interface: .other, status: .satisfied)

        // When
        await monitor.apply(wifi)
        await monitor.apply(other)

        let snapshot = await monitor.current

        // Then
        XCTAssertEqual(snapshot.status, .satisfied)
        XCTAssertEqual(snapshot.interface, .wifi)
    }

    func testApplyPreservesKnownInterfaceAcrossOfflineOnlineCycle() async {
        // Given
        let monitor: PathMonitor = .init()
        let wifi: PathMonitor.PathUpdate = .init(interface: .wifi, status: .satisfied)
        let offline: PathMonitor.PathUpdate = .init(interface: .other, status: .unsatisfied)
        let restored: PathMonitor.PathUpdate = .init(interface: .other, status: .satisfied)

        // When
        await monitor.apply(wifi)
        await monitor.apply(offline)
        await monitor.apply(restored)
        await monitor.apply(offline)

        let snapshot = await monitor.current

        // Then
        XCTAssertEqual(snapshot.status, .unsatisfied)
        XCTAssertEqual(snapshot.interface, .wifi)
    }

    func testApplyLeavesInterfaceNilWhenFirstUpdateCarriesOtherInterface() async {
        // Given
        let monitor: PathMonitor = .init()
        let update: PathMonitor.PathUpdate = .init(interface: .other, status: .satisfied)

        // When
        await monitor.apply(update)

        let snapshot = await monitor.current

        // Then
        XCTAssertEqual(snapshot.status, .satisfied)
        XCTAssertNil(snapshot.interface)
    }

    func testInterfaceClassifiesWifiPathAsWifi() {
        // Given
        let types: [NWInterface.InterfaceType] = [.wifi]

        // When
        let interface: ConnectivitySnapshot.Interface = .init(usesInterfaceType: { types.contains($0) })

        // Then
        XCTAssertEqual(interface, .wifi)
    }

    func testInterfaceClassifiesCellularPathAsCellular() {
        // Given
        let types: [NWInterface.InterfaceType] = [.cellular]

        // When
        let interface: ConnectivitySnapshot.Interface = .init(usesInterfaceType: { types.contains($0) })

        // Then
        XCTAssertEqual(interface, .cellular)
    }

    func testInterfaceClassifiesWiredEthernetPathAsWired() {
        // Given
        let types: [NWInterface.InterfaceType] = [.wiredEthernet]

        // When
        let interface: ConnectivitySnapshot.Interface = .init(usesInterfaceType: { types.contains($0) })

        // Then
        XCTAssertEqual(interface, .wired)
    }

    func testInterfaceClassifiesUnrecognizedPathAsOther() {
        // Given
        let types: [NWInterface.InterfaceType] = [.loopback, .other]

        // When
        let interface: ConnectivitySnapshot.Interface = .init(usesInterfaceType: { types.contains($0) })

        // Then
        XCTAssertEqual(interface, .other)
    }

    func testInterfaceClassifiesPathReportingNoTypeAsOther() {
        // Given
        let types: [NWInterface.InterfaceType] = []

        // When
        let interface: ConnectivitySnapshot.Interface = .init(usesInterfaceType: { types.contains($0) })

        // Then
        XCTAssertEqual(interface, .other)
    }

    func testInterfaceFavorsWifiOverCellular() {
        // Given
        let types: [NWInterface.InterfaceType] = [.cellular, .wifi]

        // When
        let interface: ConnectivitySnapshot.Interface = .init(usesInterfaceType: { types.contains($0) })

        // Then
        XCTAssertEqual(interface, .wifi)
    }

    func testInterfaceFavorsWifiOverWiredEthernet() {
        // Given
        let types: [NWInterface.InterfaceType] = [.wiredEthernet, .wifi]

        // When
        let interface: ConnectivitySnapshot.Interface = .init(usesInterfaceType: { types.contains($0) })

        // Then
        XCTAssertEqual(interface, .wifi)
    }

    func testInterfaceFavorsCellularOverWiredEthernet() {
        // Given
        let types: [NWInterface.InterfaceType] = [.wiredEthernet, .cellular]

        // When
        let interface: ConnectivitySnapshot.Interface = .init(usesInterfaceType: { types.contains($0) })

        // Then
        XCTAssertEqual(interface, .cellular)
    }

    func testInterfaceClassifiesPathReportingEveryTypeAsWifi() {
        // Given
        let types: [NWInterface.InterfaceType] = [.cellular, .loopback, .other, .wifi, .wiredEthernet]

        // When
        let interface: ConnectivitySnapshot.Interface = .init(usesInterfaceType: { types.contains($0) })

        // Then
        XCTAssertEqual(interface, .wifi)
    }
}
