//
//  MockNetworkOperationPerformer.swift
//  ImageDownloader
//
//  Created by Piotr Torczynski on 23/07/2024.
//

import Foundation
@testable import Networking

class MockNetworkOperationPerformer: NetworkOperationPerformerProtocol {
    var hasInternet: Bool
    var performNetworkOperationCalled: Bool = false

    init(hasInternet: Bool) {
        self.hasInternet = hasInternet
    }

    func hasInternetConnection() async -> Bool {
        return hasInternet
    }

    func performNetworkOperation(using closure: @escaping () async -> Void, withinSeconds timeoutDuration: TimeInterval) async throws {
        performNetworkOperationCalled = true
        if hasInternet {
            await closure()
        } else {
            throw NetworkError.noInternet
        }
    }

    enum NetworkError: Error {
        case noInternet
    }
}
