//
//  NetworkOperationPerformerTests.swift
//
//
//  Created by Piotr Torczynski on 19/07/2024.
//

import XCTest
@testable import Networking

final class NetworkOperationPerformerTests: XCTestCase {
    private var performer: NetworkOperationPerformer!
    private var networkMonitor: MockNetworkMonitor!

    override func setUp() {
        super.setUp()
        networkMonitor = MockNetworkMonitor()
        performer = NetworkOperationPerformer(networkMonitor: networkMonitor)
    }

    func testPerformNetworkOperation_withImmediateConnection() async throws {
        networkMonitor.hasInternetConnectionResult = true
        var closureCalled = false

        try await performer.performNetworkOperation(withinSeconds: 2) {
            closureCalled = true
        }

        XCTAssertTrue(closureCalled)
    }

    func testPerformNetworkOperation_withDelayedConnection() async throws {
        networkMonitor.hasInternetConnectionResult = false
        networkMonitor.delayedConnection = true
        var closureCalled = false

        let task = Task {
            try await performer.performNetworkOperation(withinSeconds: 2) {
                closureCalled = true
            }
        }

        await networkMonitor.simulateNetworkChange(connected: true)
        try await task.value

        XCTAssertTrue(closureCalled)
    }

    func testPerformNetworkOperation_withTimeout() async {
        networkMonitor.hasInternetConnectionResult = false
        var closureCalled = false

        do {
            try await performer.performNetworkOperation(withinSeconds: 1) {
                closureCalled = true
            }
        } catch {
            XCTAssertEqual((error as NSError).userInfo[NSLocalizedDescriptionKey] as? String, "Operation timed out")
        }
        
        XCTAssertFalse(closureCalled)
    }
}

private final class MockNetworkMonitor: NetworkMonitorProtocol {
    var timeOutDuration: Double = 2
    var hasInternetConnectionResult: Bool = false
    var delayedConnection: Bool = false

    func hasInternetConnection() async -> Bool {
        return hasInternetConnectionResult
    }

    func waitForConnection() async {
        while !hasInternetConnectionResult {
            if delayedConnection {
                try! await Task.sleep(nanoseconds: UInt64(timeOutDuration) * 1_000_000_000) // Simulate network connection delay
                hasInternetConnectionResult = true
            } else {
                await Task.yield()
            }
        }
    }

    func simulateNetworkChange(connected: Bool) async {
        hasInternetConnectionResult = connected
    }
}
