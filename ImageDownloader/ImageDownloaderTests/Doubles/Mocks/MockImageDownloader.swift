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
    var downloadImageResult: UIImage?

    func downloadImage(from url: URL) async throws -> UIImage {
        if let image = downloadImageResult {
            return image
        } else {
            throw URLError(.badServerResponse)
        }
    }
}
