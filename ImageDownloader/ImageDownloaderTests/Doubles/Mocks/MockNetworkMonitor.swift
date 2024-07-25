//
//  MockNetworkMonitor.swift
//  ImageDownloader
//
//  Created by Piotr Torczynski on 24/07/2024.
//

import Networking

@testable import ImageDownloader

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
