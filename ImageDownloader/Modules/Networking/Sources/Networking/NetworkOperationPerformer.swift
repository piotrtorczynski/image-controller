//
//  File.swift
//
//
//  Created by Piotr Torczynski on 19/07/2024.
//

import Foundation


public protocol NetworkOperationPerformerProtocol {
    func performNetworkOperation(using closure: @escaping () async -> Void, withinSeconds timeoutDuration: TimeInterval) async
}

public class NetworkOperationPerformer: NetworkOperationPerformerProtocol {
    private let networkMonitor: NetworkMonitorProtocol

    public init(networkMonitor: NetworkMonitorProtocol) {
        self.networkMonitor = networkMonitor
    }

    /// Attempts to perform a network operation using the given `closure`, within the given `timeoutDuration`.
    /// If the network is not accessible within the given `timeoutDuration`, the operation is not performed.
    public func performNetworkOperation(using closure: @escaping () async -> Void,
                                        withinSeconds timeoutDuration: TimeInterval) async {
        if await networkMonitor.hasInternetConnection() {
            await closure()
        } else {
            do {
                try await self.networkMonitor.waitForConnection(timeout: timeoutDuration)
                await closure()
            } catch {
                // Timeout reached or task was cancelled
            }
        }
    }
}
