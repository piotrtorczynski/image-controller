//
//  ContentViewModel.swift
//  ImageDownloader
//
//  Created by Piotr Torczynski on 23/07/2024.
//

import Foundation
import Networking
import UIKit

@MainActor
final class ContentViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case noNetwork
        case image(UIImage)
        case error(String)
    }

    @Published var state: State = .loading
    private var currentTask: Task<Void, Never>?

    private let networkOperationPerformer: NetworkOperationPerformerProtocol
    private let imageDownloader: ImageDownloaderProtocol

    init(networkOperationPerformer: NetworkOperationPerformerProtocol, imageDownloader: ImageDownloaderProtocol) {
        self.networkOperationPerformer = networkOperationPerformer
        self.imageDownloader = imageDownloader
    }

    func startLoading() {
        currentTask?.cancel()
        currentTask = Task {
            // Show "No network connection" message if network is not available within 0.5 seconds
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                if !(await networkOperationPerformer.hasInternetConnection()) {
                    self.state = .noNetwork
                }
            }

            // Attempt to download the image with a 2-second timeout
            do {
                try await networkOperationPerformer.performNetworkOperation(using: { [weak self] in
                    guard let self else { return }
                    do {
                        let url = URL(string: "https://picsum.photos/id/16/200/300")! // Replace with your image URL
                        let downloadedImage = try await self.imageDownloader.downloadImage(from: url)
                        self.state = .image(downloadedImage)
                    } catch {
                        self.state = .error("Image download failed: \(error)")
                    }
                }, withinSeconds: 2)
            } catch {
                state = .error("Image download failed: \(error.localizedDescription)")
            }

            if case .loading = state {
                state = .error("Image download timed out")
            }
        }
    }

    func cancelLoading() {
        currentTask?.cancel()
    }
}
