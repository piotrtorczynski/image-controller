//
//  MockImageDownloader.swift
//  ImageDownloader
//
//  Created by Piotr Torczynski on 23/07/2024.
//

import Foundation
import UIKit
@testable import Networking

struct MockImageDownloader: ImageDownloaderProtocol {
    let result: Result<UIImage, Error>

    func downloadImage(from url: URL) async throws -> UIImage {
        switch result {
        case .success(let image):
            return image
        case .failure(let error):
            throw error
        }
    }
}
