//
//  MockNetworkMonitor.swift
//
//
//  Created by Piotr Torczynski on 19/07/2024.
//

import Foundation

@testable import Networking

class MockNetworkMonitor: NetworkMonitorProtocol {
    var isConnected: Bool = false
    var onStatusChange: ((Bool) -> Void)?

    func hasInternetConnection() -> Bool {
        return isConnected
    }

    func waitForConnection() async throws {
        guard !isConnected else { return }
        await withCheckedContinuation { continuation in
            self.onStatusChange = { connected in
                if connected {
                    continuation.resume()
                }
            }
        }
    }
}
