//
//  ContentView.swift
//  ImageDownloader
//
//  Created by Piotr Torczynski on 19/07/2024.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var viewModel: ContentViewModel

    init(viewModel: ContentViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                LoadingView(showNoNetworkMessage: false)
            case .noNetwork:
                LoadingView(showNoNetworkMessage: true)
            case .image(let image):
                ImageView(image: image)
            case .error(let message):
                ErrorView(message: message)
            }
        }
        .task { await viewModel.startLoading() }
    }
}

private struct LoadingView: View {
    var showNoNetworkMessage: Bool

    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .padding()
            if showNoNetworkMessage {
                Text("Waiting for network connection")
                    .foregroundColor(.red)
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

private struct ImageView: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

private struct ErrorView: View {
    let message: String

    var body: some View {
        Text(message)
            .foregroundColor(.red)
    }
}
