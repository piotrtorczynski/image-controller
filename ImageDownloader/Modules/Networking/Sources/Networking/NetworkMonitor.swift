// The Swift Programming Language
// https://docs.swift.org/swift-book


import Foundation
import Network

public protocol NetworkMonitorProtocol {
    func hasInternetConnection() async -> Bool
    func waitForConnection(timeout: TimeInterval) async throws
}

enum NetworkMonitorError: Error {
    case timeout
}

actor NetworkMonitor: NetworkMonitorProtocol {
    private let monitor = NWPathMonitor()
    private var isConnected: Bool = false

    init() {
        Task { await self.startMonitoring() }
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { path in
            Task { await self.updateConnectionStatus(path.status == .satisfied) }
        }
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }

    private func updateConnectionStatus(_ status: Bool) {
        isConnected = status
    }

    func hasInternetConnection() async -> Bool {
        return isConnected
    }

    func waitForConnection(timeout: TimeInterval) async throws {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if await hasInternetConnection() {
                return
            }
            try await Task.sleep(nanoseconds: 500_000_000) // Check every 0.5 seconds
        }
        throw NetworkMonitorError.timeout
    }


}

