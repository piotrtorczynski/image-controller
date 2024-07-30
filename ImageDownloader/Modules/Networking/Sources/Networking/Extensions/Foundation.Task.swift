//
//  Foundation.Task.swift
//  Networking
//
//  Created by Piotr Torczynski on 29/07/2024.
//

import Foundation

public extension Task where Success == Never, Failure == Never {
    /// Race for the first result by any of the provided tasks.
    ///
    /// This will return the first valid result or throw the first thrown error by any task.
    static func race<Output>(firstResolved tasks: [Task<Output, Error>]) async throws -> Output {
        assert(!tasks.isEmpty, "You must race at least 1 task.")

        return try await withThrowingTaskGroup(of: Output.self) { group -> Output in
            for task in tasks {
                group.addTask {
                    try await task.value
                }
            }

            defer { group.cancelAll() }

            if let firstToResolve = try await group.next() {
                return firstToResolve
            } else {
                // There will be at least 1 task.
                fatalError("At least 1 task should be scheduled.")
            }
        }
    }

}
