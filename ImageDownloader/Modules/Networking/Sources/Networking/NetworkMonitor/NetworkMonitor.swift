// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Network

/// A protocol defining methods for monitoring network connectivity.
public protocol NetworkMonitorProtocol {
    func hasInternetConnection() async -> Bool
    func waitForConnection(timeout: TimeInterval) async throws
}

/// An actor that monitors network connectivity using NWPathMonitor.
public actor NetworkMonitor: NetworkMonitorProtocol {
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var currentStatus: NWPath.Status = .unsatisfied
    private var continuation: CheckedContinuation<Void, Error>?

    public init() {
        self.monitor = NWPathMonitor()
        Task {
            await startMonitoring()
        }
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task {
                await self?.notifyCurrentStatus(with: path)
                await self?.notifyStatusChange(connected: path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }

    public func hasInternetConnection() async -> Bool {
        return currentStatus == .satisfied
    }

    public func waitForConnection(timeout: TimeInterval) async throws {
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
            self.continuation = continuation
        }
    }

    private func notifyStatusChange(connected: Bool) async {
        if connected, let continuation {
            continuation.resume()
            self.continuation = nil
        }
    }

    private func notifyCurrentStatus(with path: NWPath) async {
        currentStatus = path.status
    }
}
