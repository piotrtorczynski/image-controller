//
//  ContentViewModelTests.swift
//  ImageDownloaderTests
//
//  Created by Piotr Torczynski on 19/07/2024.
//

import XCTest
import Networking
@testable import ImageDownloader

@MainActor
class ContentViewModelTests: XCTestCase {
    func testLoadingState_showsNoNetwork() async {
        let monitor = MockNetworkMonitor()
        monitor.isConnected = false
        let downloader = MockImageDownloader()
        let viewModel = ContentViewModel(networkOperationPerformer: NetworkOperationPerformer(networkMonitor: monitor), imageDownloader: downloader)

        Task {
            await viewModel.startLoading()
        }

        do {
            try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
        } catch {
            XCTFail(error.localizedDescription)
        }
        XCTAssertEqual(viewModel.state, .noNetwork)
    }

    func testLoadingState_downloadsImageSuccessfully() async {
        let monitor = MockNetworkMonitor()
        monitor.isConnected = true
        let downloader = MockImageDownloader()
        let viewModel = ContentViewModel(networkOperationPerformer: NetworkOperationPerformer(networkMonitor: monitor), imageDownloader: downloader)

        Task {
            await viewModel.startLoading()
        }

        do {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        } catch {
            XCTFail(error.localizedDescription)
        }
        XCTAssertEqual(viewModel.state, .image(UIImage()))
    }

    func testLoadingState_imageDownloadFails() async {
        let monitor = MockNetworkMonitor()
        monitor.isConnected = true
        let downloader = MockImageDownloader()
        downloader.shouldSucceed = false
        let viewModel = ContentViewModel(networkOperationPerformer: NetworkOperationPerformer(networkMonitor: monitor), imageDownloader: downloader)

        Task {
            await viewModel.startLoading()
        }

        do {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        } catch {
            XCTFail(error.localizedDescription)
        }

        switch viewModel.state {
        case .error(let message):
            XCTAssertTrue(message.contains("Image download failed"))
        default:
            XCTFail("Wrong state")
        }
    }

    func testLoadingState_imageDownloadTimeout() async {
        let monitor = MockNetworkMonitor()
        monitor.isConnected = true
        let downloader = MockImageDownloader()
        downloader.delay = 3 // 3 seconds, which is longer than the 2 seconds timeout
        let viewModel = ContentViewModel(networkOperationPerformer: NetworkOperationPerformer(networkMonitor: monitor), imageDownloader: downloader)

        Task {
            await viewModel.startLoading()
        }

        do {
            try await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds to allow for timeout
        } catch {
            XCTFail(error.localizedDescription)
        }


        XCTAssertEqual(viewModel.state, .error("Image download timed out"))
    }
}
