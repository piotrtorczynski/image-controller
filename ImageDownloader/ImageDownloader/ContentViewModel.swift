//
//  ContentViewModel.swift
//  ImageDownloader
//
//  Created by Piotr Torczynski on 23/07/2024.
//

import Foundation
import UIKit
import Networking

@MainActor
class ContentViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case noNetwork
        case image(UIImage)
        case error(String)
    }

    @Published var state: State = .loading

    private let networkOperationPerformer: NetworkOperationPerformerProtocol
    private let imageDownloader: ImageDownloaderProtocol

    init(networkOperationPerformer: NetworkOperationPerformerProtocol, imageDownloader: ImageDownloaderProtocol) {
        self.networkOperationPerformer = networkOperationPerformer
        self.imageDownloader = imageDownloader
    }

    /// Starts loading the image while handling network state changes and timeouts.
    func startLoading() async {
        let noNetworkCheckTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            if !(await networkOperationPerformer.hasInternetConnection()) {
                self.state = .noNetwork
            }
        }

        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            if case .loading = self.state {
                self.state = .error("Image download timed out")
            }
        }

        do {
            try await networkOperationPerformer.performNetworkOperation(using: { [weak self] in
                guard let self else { return }
                do {
                    let url = URL(string: "https://picsum.photos/id/16/200/300")!
                    let downloadedImage = try await self.imageDownloader.downloadImage(from: url)
                    self.state = .image(downloadedImage)
                } catch {
                    self.state = .error("Image download failed: \(error)")
                }
            }, withinSeconds: 4)
        } catch {
            state = .error("Image download failed: \(error.localizedDescription)")
        }

        // Ensure the noNetwork check completes before evaluating final state
        await noNetworkCheckTask.value
        await timeoutTask.value
    }
}

