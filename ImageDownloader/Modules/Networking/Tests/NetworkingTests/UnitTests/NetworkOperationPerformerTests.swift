//
//  NetworkOperationPerformerTests.swift
//  
//
//  Created by Piotr Torczynski on 19/07/2024.
//

import XCTest
@testable import Networking

final class NetworkOperationPerformerTests: XCTestCase {

    func testPerformNetworkOperation_withImmediateConnection() async throws {
        let monitor = MockNetworkMonitor(isConnected: true)
        let performer = NetworkOperationPerformer(networkMonitor: monitor)

        var closureCalled = false
        try await performer.performNetworkOperation(using: {
            closureCalled = true
        }, withinSeconds: 2)

        XCTAssertTrue(closureCalled, "The closure should have been called immediately.")
    }

    func testPerformNetworkOperation_withDelayedConnection() async throws {
        let monitor = MockNetworkMonitor(isConnected: false)
        let performer = NetworkOperationPerformer(networkMonitor: monitor)

        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // Simulate a delay of 0.5 seconds
            await monitor.setConnectionStatus(to: true)
        }

        var closureCalled = false
        try await performer.performNetworkOperation(using: {
            closureCalled = true
        }, withinSeconds: 2)

        XCTAssertTrue(closureCalled, "The closure should have been called after the connection was established.")
    }

    func testPerformNetworkOperation_withTimeout() async throws {
        let monitor = MockNetworkMonitor(isConnected: false)
        let performer = NetworkOperationPerformer(networkMonitor: monitor)

        var closureCalled = false
        do {
            try await performer.performNetworkOperation(using: {
                closureCalled = true
            }, withinSeconds: 1)
        } catch {
            // Expected error due to timeout
        }

        XCTAssertFalse(closureCalled, "The closure should not have been called due to timeout.")
    }

    func testPerformNetworkOperation_withCancellation() async throws {
        let monitor = MockNetworkMonitor(isConnected: false)
        let performer = NetworkOperationPerformer(networkMonitor: monitor)

        let task = Task {
            var closureCalled = false
            do {
                try await performer.performNetworkOperation(using: {
                    closureCalled = true
                }, withinSeconds: 5)
            } catch {
                // Expected error due to cancellation
            }

            XCTAssertFalse(closureCalled, "The closure should not have been called due to cancellation.")
        }

        task.cancel()

        try await Task.sleep(nanoseconds: 1_000_000_000) // Allow some time for cancellation to take effect
    }
}

private actor MockNetworkMonitor: NetworkMonitorProtocol {
    var isConnected: Bool

    init(isConnected: Bool) {
        self.isConnected = isConnected
    }

    func hasInternetConnection() async -> Bool {
        return isConnected
    }

    func waitForConnection(timeout: TimeInterval) async throws {
        guard await !hasInternetConnection() else { return }

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.waitForConnectionContinuation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw URLError(.timedOut)
            }

            try await group.next()
            group.cancelAll()
        }
    }

    private func waitForConnectionContinuation() async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                await self.checkConnection(continuation: continuation)
            }
        }
    }

    private func checkConnection(continuation: CheckedContinuation<Void, Error>) async {
        if isConnected {
            continuation.resume()
        } else {
            Task {
                try await Task.sleep(nanoseconds: 500_000_000) // Simulate some delay
                if isConnected {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: URLError(.timedOut))
                }
            }
        }
    }
}

private extension MockNetworkMonitor {
    func setConnectionStatus(to status: Bool) async {
        isConnected = status
    }
}

