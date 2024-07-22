//
//  NetworkOperationPerformerTests.swift
//  
//
//  Created by Piotr Torczynski on 19/07/2024.
//

import XCTest

@testable import Networking

final class NetworkOperationPerformerTests: XCTestCase {
    func testPerformNetworkOperationWhenInitiallyConnected() async {
        let monitor = MockNetworkMonitor(isConnected: true)
        let performer = NetworkOperationPerformer(networkMonitor: monitor)
        var closureCalled = false

        await performer.performNetworkOperation(using: {
            closureCalled = true
        }, withinSeconds: 5)

        XCTAssertTrue(closureCalled, "Closure should be called when network is initially connected.")
    }

    func testPerformNetworkOperationWhenInitiallyDisconnectedButThenConnected() async {
        let monitor = MockNetworkMonitor(isConnected: false)
        let performer = NetworkOperationPerformer(networkMonitor: monitor)
        var closureCalled = false

        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network becoming available after 1 second
            monitor.setConnectionStatus(true)
        }

        await performer.performNetworkOperation(using: {
            closureCalled = true
        }, withinSeconds: 5)

        XCTAssertTrue(closureCalled, "Closure should be called when network becomes available within timeout duration.")
    }

    func testPerformNetworkOperationWhenNetworkBecomesAvailableAfterTimeout() async {
        let monitor = MockNetworkMonitor(isConnected: false, shouldTimeout: true)
        let performer = NetworkOperationPerformer(networkMonitor: monitor)
        var closureCalled = false

        Task {
            try await Task.sleep(nanoseconds: 6_000_000_000) // Simulate network becoming available after 6 seconds (after timeout)
            monitor.setConnectionStatus(true)
        }

        await performer.performNetworkOperation(using: {
            closureCalled = true
        }, withinSeconds: 5)

        XCTAssertFalse(closureCalled, "Closure should not be called when network becomes available after timeout duration.")
    }
}


