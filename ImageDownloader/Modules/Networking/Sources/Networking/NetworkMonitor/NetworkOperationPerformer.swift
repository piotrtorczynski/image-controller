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

/// Protocol defining methods for performing network operations.
public protocol NetworkOperationPerformerProtocol {
    /// Attempts to perform a network operation within the given timeout duration.
      /// - Parameters:
      ///   - closure: The network operation to be performed.
      ///   - timeoutDuration: The timeout duration within which the operation should be performed.
      /// - Throws: An error if the operation times out or is cancelled.

    func performNetworkOperation(withinSeconds timeoutDuration: TimeInterval, using closure: @escaping () async -> Void) async throws
    
    /// Checks if there is an active internet connection.
      /// - Returns: A boolean indicating the presence of an internet connection.
    func hasInternetConnection() async -> Bool
}

/// Class responsible for performing network operations with a given timeout.
public class NetworkOperationPerformer: NetworkOperationPerformerProtocol {
    private let networkMonitor: NetworkMonitorProtocol

    public init(networkMonitor: NetworkMonitorProtocol) {
        self.networkMonitor = networkMonitor
    }

    public func performNetworkOperation(withinSeconds timeoutDuration: TimeInterval, using closure: @escaping () async -> Void) async throws {
        if await networkMonitor.hasInternetConnection() {
            await closure()
        } else {
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: UInt64(timeoutDuration * 1_000_000_000))
                throw URLError(.timedOut)
            }

            let networkTask = Task {
                try await networkMonitor.waitForConnection()
                await closure()
            }

            try await Task.race(firstResolved: [timeoutTask, networkTask])
        }
    }

    public func hasInternetConnection() async -> Bool {
        return await networkMonitor.hasInternetConnection()
    }
}
