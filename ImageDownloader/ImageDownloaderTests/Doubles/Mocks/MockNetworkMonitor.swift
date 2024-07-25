//
//  MockNetworkMonitor.swift
//  ImageDownloader
//
//  Created by Piotr Torczynski on 24/07/2024.
//

import Networking
@testable import ImageDownloader

class MockNetworkMonitor: NetworkMonitorProtocol {
    var isConnected: Bool

    init(isConnected: Bool) {
        self.isConnected = isConnected
    }

    func hasInternetConnection() async -> Bool {
        return isConnected
    }

    func waitForConnection() async {
        while !isConnected {
            try? await Task.sleep(nanoseconds: 100_000_000) // Check every 0.1 seconds
        }
    }
}
