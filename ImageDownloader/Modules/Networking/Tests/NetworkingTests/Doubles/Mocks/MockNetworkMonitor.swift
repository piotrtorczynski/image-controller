//
//  MockNetworkMonitor.swift
//
//
//  Created by Piotr Torczynski on 19/07/2024.
//

import Foundation

@testable import Networking

class MockNetworkMonitor: NetworkMonitorProtocol {
    private var isConnected: Bool
    private var shouldTimeout: Bool

    init(isConnected: Bool, shouldTimeout: Bool = false) {
        self.isConnected = isConnected
        self.shouldTimeout = shouldTimeout
    }

    func hasInternetConnection() async -> Bool {
        return isConnected
    }

    func waitForConnection(timeout: TimeInterval) async throws {
        if shouldTimeout {
            throw NetworkMonitor.NetworkMonitorError.timeout
        }
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if isConnected {
                return
            }
            try await Task.sleep(nanoseconds: 500_000_000) // Simulate waiting
        }
        throw NetworkMonitor.NetworkMonitorError.timeout
    }

    func setConnectionStatus(_ status: Bool) {
        isConnected = status
    }
}
