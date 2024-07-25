// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

import Network

/// A protocol defining methods for monitoring network connectivity.
public protocol NetworkMonitorProtocol {
    func hasInternetConnection() async -> Bool
    func waitForConnection() async throws
}

///// An actor that monitors network connectivity using NWPathMonitor.
public actor NetworkMonitor: NetworkMonitorProtocol {
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var currentStatus: NWPath.Status = .unsatisfied
    private var onStatusChange: ((Bool) -> Void)?

    public init() {
        self.monitor = NWPathMonitor()
        Task { await startMonitoring() }
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { [weak self] in
                guard let self else { return }
                let connected = path.status == .satisfied
                await self.notifyCurrentStatus(wiht: path)
                await self.notifyStatusChange(connected: connected)
            }
        }
        monitor.start(queue: queue)
    }

    public func hasInternetConnection() async -> Bool {
        return currentStatus == .satisfied
    }

    public func waitForConnection() async throws {
        guard await !hasInternetConnection() else { return }
        try await withCheckedThrowingContinuation { continuation in
            self.onStatusChange = { connected in
                if connected {
                    continuation.resume()
                }
            }
        }
    }

    private func notifyStatusChange(connected: Bool) async {
        onStatusChange?(connected)
    }

    private func notifyCurrentStatus(wiht path: NWPath) async {
        currentStatus = path.status
    }
}
