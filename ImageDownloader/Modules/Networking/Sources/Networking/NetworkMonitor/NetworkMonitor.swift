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
    
    private var continuation: AsyncStream<NWPath>.Continuation?
    private var streamContinuation: AsyncStream<Void>.Continuation?

    public init(monitor: NetworkPathMonitorProtocol = NWPathMonitor()) {
        self.monitor = monitor
        Task { await startMonitoring() }
    }

    private func startMonitoring() async {
        let stream = AsyncStream<NWPath> { continuation in
            self.continuation = continuation
            monitor.pathUpdateHandler = { path in
                continuation.yield(path)
            }
        }
        monitor.start(queue: queue)

        Task {
            for await path in stream {
                await self.notifyCurrentStatus(with: path)
            }
        }
    }

    public func hasInternetConnection() async -> Bool {
        return currentStatus == .satisfied
    }

    public func waitForConnection() async throws {
        guard await !hasInternetConnection() else { return }

        let stream = AsyncStream<Void> { continuation in
            self.streamContinuation = continuation
        }

        for await _ in stream {
            if await hasInternetConnection() {
                return
            }
        }

        throw URLError(.timedOut)
    }

    private func notifyCurrentStatus(with path: NWPath) async {
        currentStatus = path.status
        if path.status == .satisfied {
            streamContinuation?.yield()
        }
    }
}
