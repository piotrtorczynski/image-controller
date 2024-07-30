//
//  ContentViewModel.swift
//  ImageDownloader
//
//  Created by Piotr Torczynski on 23/07/2024.
//

//import SwiftUI
import UIKit
import Networking

@MainActor
class ContentViewModel: ObservableObject {
    enum State {
        case loading
        case noNetwork
        case image(UIImage)
        case error(String)
    }

    @Published var state: State = .loading

    private let networkOperationPerformer: NetworkOperationPerformerProtocol
    private let imageDownloader: ImageDownloaderProtocol

    private var tasks: Set<Task<Void, Never>> = []

    init(networkOperationPerformer: NetworkOperationPerformerProtocol, imageDownloader: ImageDownloaderProtocol) {
        self.networkOperationPerformer = networkOperationPerformer
        self.imageDownloader = imageDownloader
    }

    func startLoading() async {
        state = .loading

        let task = Task {
            // Show "No network connection" message if network is not available within 0.5 seconds
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            if await !networkOperationPerformer.hasInternetConnection() {
                self.state = .noNetwork
            }

            // Attempt to download the image with a 2-second timeout
            do {
                try await networkOperationPerformer.performNetworkOperation(withinSeconds: 2) { [weak self] in
                    guard let self = self else { return }
                    do {
                        let url = URL(string: "https://picsum.photos/id/16/200/300")! // Replace with your image URL
                        let downloadedImage = try await self.imageDownloader.downloadImage(from: url)
                        self.state = .image(downloadedImage)
                    } catch {
                        self.state = .error("Image download failed: \(error)")
                    }
                }
            } catch {
                if case .loading = state {
                    self.state = .error("Image download failed: \(error.localizedDescription)")
                }
            }

            if case .loading = state {
                self.state = .error("Image download timed out")
            }
        }
        tasks.insert(task)
    }

    func cancelLoading() {
        for task in tasks {
            task.cancel()
        }
        tasks.removeAll()
    }
}
