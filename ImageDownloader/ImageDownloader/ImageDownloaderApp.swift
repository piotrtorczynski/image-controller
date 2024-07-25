//
//  ImageDownloaderApp.swift
//  ImageDownloader
//
//  Created by Piotr Torczynski on 19/07/2024.
//

import SwiftUI
import Networking

@main
struct ImageDownloaderApp: App {
    var body: some Scene {
        WindowGroup {
            let networkMonitor = NetworkMonitor()
            let imageDownloader = ImageDownloader()
            let networkOperationPerformer = NetworkOperationPerformer(networkMonitor: networkMonitor)
            ContentView(viewModel: ContentViewModel(networkOperationPerformer: networkOperationPerformer, imageDownloader: imageDownloader))
        }
    }
}
