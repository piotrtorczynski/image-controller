//
//  NetworkOperationPerformerTests.swift
//  
//
//  Created by Piotr Torczynski on 19/07/2024.
//

import XCTest

@testable import Networking

final class NetworkOperationPerformerTests: XCTestCase {
    func testPerformNetworkOperation_withInternet() async throws {
        let monitor = MockNetworkMonitor()
        monitor.isConnected = true
        let performer = NetworkOperationPerformer(networkMonitor: monitor)

        var closureCalled = false
        try await performer.performNetworkOperation(using: {
            closureCalled = true
        }, withinSeconds: 2)

        XCTAssertTrue(closureCalled)
    }

    func testPerformNetworkOperation_noInternetInitially_thenConnected() async throws {
        let monitor = MockNetworkMonitor()
        monitor.isConnected = false
        let performer = NetworkOperationPerformer(networkMonitor: monitor)

        var closureCalled = false

        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate delay
            monitor.isConnected = true
            monitor.onStatusChange?(true)
        }

        try await performer.performNetworkOperation(using: {
            closureCalled = true
        }, withinSeconds: 2)

        XCTAssertTrue(closureCalled)
    }
}
