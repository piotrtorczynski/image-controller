//
//  File.swift
//
//
//  Created by Piotr Torczynski on 19/07/2024.
//

import Foundation

public protocol NetworkOperationPerformerProtocol {
    /// Performs a network operation using the given closure within a specified timeout duration.
    /// - Parameters:
    ///   - closure: The closure to be executed if the network is available.
    ///   - timeoutDuration: The duration within which the network operation should be performed.
    /// - Throws: An error if the operation times out or if there is no internet connection.
    func performNetworkOperation(using closure: @escaping () async -> Void, withinSeconds timeoutDuration: TimeInterval) async throws

    /// Checks if the device currently has an internet connection.
    /// - Returns: A boolean indicating whether there is an internet connection.
    func hasInternetConnection() async -> Bool
}

public class NetworkOperationPerformer: NetworkOperationPerformerProtocol {
    private let networkMonitor: NetworkMonitorProtocol

    public init(networkMonitor: NetworkMonitorProtocol) {
        self.networkMonitor = networkMonitor
    }

    public func hasInternetConnection() async -> Bool {
        return await networkMonitor.hasInternetConnection()
    }

    public func performNetworkOperation(using closure: @escaping () async -> Void, withinSeconds timeoutDuration: TimeInterval) async throws {
        try await networkMonitor.waitForConnection()

        // After waiting for the connection, check again if connected
        guard await networkMonitor.hasInternetConnection() else {
            throw NetworkError.noConnection
        }

        let timeoutTask = Task { () -> Void in
            try await Task.sleep(nanoseconds: UInt64(timeoutDuration * 1_000_000_000))
            throw NetworkError.timeout
        }

        let operationTask = Task { () -> Void in
            await closure()
        }

        do {
            try await withTaskCancellationHandler {
                timeoutTask.cancel()
            } operation: {
                try await operationTask.value
            }
        } catch {
            timeoutTask.cancel()
            operationTask.cancel()
            throw error
        }
    }
}

public enum NetworkError: Error {
    case noConnection
    case timeout
}
