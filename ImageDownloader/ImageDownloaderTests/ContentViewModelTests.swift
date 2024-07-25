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
final class ContentViewModelTests: XCTestCase {
    func testStartLoading_withImmediateConnection() async throws {
        let monitor = MockNetworkMonitor(isConnected: true)
        let downloader = MockImageDownloader(result: .success(UIImage()))
        let viewModel = ContentViewModel(networkOperationPerformer: NetworkOperationPerformer(networkMonitor: monitor), imageDownloader: downloader)

        viewModel.startLoading()

        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay to allow operation to complete
        XCTAssertTrue(viewModel.state == .image(UIImage()))
    }

    func testStartLoading_withDelayedConnection() async throws {
        let monitor = MockNetworkMonitor(isConnected: false)
        let downloader = MockImageDownloader(result: .success(UIImage()))
        let viewModel = ContentViewModel(networkOperationPerformer: NetworkOperationPerformer(networkMonitor: monitor), imageDownloader: downloader)

        viewModel.startLoading()

        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            monitor.isConnected = true
        }

        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds delay to allow operation to complete
        XCTAssertTrue(viewModel.state == .image(UIImage()))
    }

    func testStartLoading_withTimeout() async {
        let monitor = MockNetworkMonitor(isConnected: false)
        let downloader = MockImageDownloader(result: .success(UIImage()))
        let viewModel = ContentViewModel(networkOperationPerformer: NetworkOperationPerformer(networkMonitor: monitor), imageDownloader: downloader)

        viewModel.startLoading()

        try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds delay to ensure timeout occurs
        XCTAssertTrue(viewModel.state == .error("Image download timed out"))
    }

    func testCancelLoading() async {
        let monitor = MockNetworkMonitor(isConnected: false)
        let downloader = MockImageDownloader(result: .success(UIImage()))
        let viewModel = ContentViewModel(networkOperationPerformer: NetworkOperationPerformer(networkMonitor: monitor), imageDownloader: downloader)

        viewModel.startLoading()
        viewModel.cancelLoading()

        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay to ensure cancellation takes effect
        XCTAssertTrue(viewModel.state == .loading) // Assuming the state remains loading after cancellation
    }
}
