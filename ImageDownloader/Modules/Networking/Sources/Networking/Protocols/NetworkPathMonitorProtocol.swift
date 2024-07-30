//
//  NetworkPathMonitorProtocol.swift
//  Networking
//
//  Created by Piotr Torczynski on 29/07/2024.
//

import Foundation
import Network

public protocol NetworkPathMonitorProtocol {
    var pathUpdateHandler: (@Sendable (_ newPath: NWPath) -> Void)? { get set }
    func start(queue: DispatchQueue)
}

extension NWPathMonitor: NetworkPathMonitorProtocol {}
