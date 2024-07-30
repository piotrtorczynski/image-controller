//
//  MockNetworkOperationPerformer.swift
//  ImageDownloader
//
//  Created by Piotr Torczynski on 23/07/2024.
//

import Foundation
@testable import Networking

class MockNetworkOperationPerformer: NetworkOperationPerformerProtocol {
    var hasInternetConnectionResult: Bool = false
    var performNetworkOperationShouldTimeout: Bool = false

    func hasInternetConnection() async -> Bool {
        return hasInternetConnectionResult
    }

    func performNetworkOperation(withinSeconds timeoutDuration: TimeInterval, using closure: @escaping () async -> Void) async throws {
        if performNetworkOperationShouldTimeout {
            try await Task.sleep(nanoseconds: UInt64(timeoutDuration * 1_000_000_000))
            throw NSError(domain: "NetworkOperationPerformer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Operation timed out"])
        } else if hasInternetConnectionResult {
            await closure()
        }
    }
}
