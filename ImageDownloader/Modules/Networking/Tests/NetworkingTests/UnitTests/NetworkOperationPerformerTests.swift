//
//  NetworkOperationPerformerTests.swift
//
//
//  Created by Piotr Torczynski on 19/07/2024.
//

import XCTest
@testable import Networking

final class NetworkOperationPerformerTests: XCTestCase {
    var performer: NetworkOperationPerformer!
    private var networkMonitor: MockNetworkMonitor!

    override func setUp() {
        super.setUp()
        networkMonitor = MockNetworkMonitor()
        performer = NetworkOperationPerformer(networkMonitor: networkMonitor)
    }

    override func tearDown() {
        performer = nil
        networkMonitor = nil
        super.tearDown()
    }

    func testPerformNetworkOperation_withImmediateConnection() async throws {
        networkMonitor.hasInternet = true
        var closureCalled = false

        try await performer.performNetworkOperation(withinSeconds: 2) {
            closureCalled = true
        }

        XCTAssertTrue(closureCalled)
    }

    func testPerformNetworkOperation_withDelayedConnection() async throws {
        networkMonitor.hasInternet = false
        var closureCalled = false

        let networkTask = Task {
            try await Task.sleep(nanoseconds: 500_000_000)
            self.networkMonitor.hasInternet = true
            self.networkMonitor.notifyStatusChange(connected: true)
        }

        try await performer.performNetworkOperation(withinSeconds: 2) {
            closureCalled = true
        }

        try await networkTask.value
        XCTAssertTrue(closureCalled)
    }

    func testPerformNetworkOperation_withTimeout() async throws {
        networkMonitor.hasInternet = false
        var closureCalled = false

        do {
            try await performer.performNetworkOperation(withinSeconds: 1) {
                closureCalled = true
            }
            XCTFail("Expected to throw timeout error")
        } catch {
            XCTAssertFalse(closureCalled)
        }
    }
}

private class MockNetworkMonitor: NetworkMonitorProtocol {
    var hasInternet: Bool = false
    private var continuation: CheckedContinuation<Void, Never>?

    func hasInternetConnection() async -> Bool {
        return hasInternet
    }

    func waitForConnection() async throws {
        guard !hasInternet else { return }

        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func notifyStatusChange(connected: Bool) {
        hasInternet = connected
        continuation?.resume()
        continuation = nil
    }
}
