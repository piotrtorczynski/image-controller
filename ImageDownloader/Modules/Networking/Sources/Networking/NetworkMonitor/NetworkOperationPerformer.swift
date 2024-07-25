//
//  File.swift
//
//
//  Created by Piotr Torczynski on 19/07/2024.
//

import Foundation

enum NetworkOperationPerformerError: Error {
    case timeout
    case cancelled
}

import Foundation

/// Protocol for performing network operations.
public protocol NetworkOperationPerformerProtocol {
    func performNetworkOperation(using closure: @escaping () async -> Void, withinSeconds timeoutDuration: TimeInterval) async throws
    func hasInternetConnection() async -> Bool
}

/// A class responsible for performing network operations.
public class NetworkOperationPerformer: NetworkOperationPerformerProtocol {
    private let networkMonitor: NetworkMonitorProtocol

    public init(networkMonitor: NetworkMonitorProtocol) {
        self.networkMonitor = networkMonitor
    }

    /// Attempts to perform a network operation within the given timeout duration.
    /// - Parameters:
    ///   - closure: The network operation to be performed.
    ///   - timeoutDuration: The timeout duration within which the operation should be performed.
    /// - Throws: An error if the operation times out or is cancelled.
    public func performNetworkOperation(using closure: @escaping () async -> Void, withinSeconds timeoutDuration: TimeInterval) async throws {
        if await networkMonitor.hasInternetConnection() {
            await closure()
        } else {
            do {
                try await withTaskCancellationHandler {
                    try await networkMonitor.waitForConnection(timeout: timeoutDuration)
                    await closure()
                } onCancel: {
                    // Handle cancellation
                }
            } catch {
                throw error
            }
        }
    }

    /// Checks if there is an active internet connection.
    /// - Returns: A boolean indicating the presence of an internet connection.
    public func hasInternetConnection() async -> Bool {
        return await networkMonitor.hasInternetConnection()
    }
}
