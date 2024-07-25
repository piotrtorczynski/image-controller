//
//  ImageDownloader.swift
//  Networking
//
//  Created by Piotr Torczynski on 23/07/2024.
//

import UIKit

public enum ImageDownloaderError: Error {
    case dataConversionFailed
}

public protocol ImageDownloaderProtocol {
    func downloadImage(from url: URL) async throws -> UIImage
}

public class ImageDownloader: ImageDownloaderProtocol {
    public init() {}

    /// Allows to download specific image
    /// - Parameter url: a url for the image
    /// - Returns: downloaded image or thrown error
    public func downloadImage(from url: URL) async throws -> UIImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw ImageDownloaderError.dataConversionFailed
        }
        return image
    }
}
