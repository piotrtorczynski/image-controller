import Foundation
import Network

public protocol NetworkMonitorProtocol {
    func hasInternetConnection() async -> Bool
    func waitForConnection() async throws
}

public actor NetworkMonitor: NetworkMonitorProtocol {
    private var monitor: NetworkPathMonitorProtocol
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var currentStatus: NWPath.Status = .unsatisfied
    private var streamContinuation: AsyncStream<Void>.Continuation?

    public init(monitor: NetworkPathMonitorProtocol = NWPathMonitor()) {
        self.monitor = monitor
        Task { await startMonitoring() }
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task {
                await self?.onPathUpdate(path)
            }
        }
        monitor.start(queue: queue)
    }

    public func hasInternetConnection() async -> Bool {
        return currentStatus == .satisfied
    }

    public func waitForConnection() async throws {
        guard await !hasInternetConnection() else { return }

        let stream: AsyncStream<Void>? = AsyncStream { continuation in
            streamContinuation = continuation
        }

        guard let stream = stream else { throw URLError(.cannotFindHost) }

        for await _ in stream {
            if await hasInternetConnection() {
                return
            }
        }

        throw URLError(.timedOut)
    }

    private func notifyCurrentStatus(with path: NWPath) async {
        currentStatus = path.status
    }

    private func onPathUpdate(_ path: NWPath) async {
        await notifyCurrentStatus(with: path)
        if path.status == .satisfied {
            streamContinuation?.yield()
        }
    }
}
