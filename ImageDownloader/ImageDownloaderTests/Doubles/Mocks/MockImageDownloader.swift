//
//  MockImageDownloader.swift
//  ImageDownloader
//
//  Created by Piotr Torczynski on 23/07/2024.
//

import Foundation
import UIKit
@testable import Networking

class MockImageDownloader: ImageDownloaderProtocol {
    var shouldSucceed = true
    var delay: TimeInterval = 0

    func downloadImage(from url: URL) async throws -> UIImage {
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        if shouldSucceed {
            return UIImage()
        } else {
            throw URLError(.badURL)
        }
    }
}
