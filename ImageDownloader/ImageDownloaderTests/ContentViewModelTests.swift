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
    var viewModel: ContentViewModel!
    var networkOperationPerformer: MockNetworkOperationPerformer!
    var imageDownloader: MockImageDownloader!

    override func setUp() {
        super.setUp()
        networkOperationPerformer = MockNetworkOperationPerformer()
        imageDownloader = MockImageDownloader()
        viewModel = ContentViewModel(networkOperationPerformer: networkOperationPerformer, imageDownloader: imageDownloader)
    }

    func testStartLoading_noNetwork() async {
        networkOperationPerformer.hasInternetConnectionResult = false
        let expectation = XCTestExpectation(description: "Wait for state change")

        Task {
            await viewModel.startLoading()
            try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
            if case .noNetwork = viewModel.state {
                expectation.fulfill()
            } else {
                XCTFail("Expected state to be .noNetwork but got \(viewModel.state)")
            }
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testStartLoading_withNetwork() async {
        networkOperationPerformer.hasInternetConnectionResult = true
        imageDownloader.downloadImageResult = UIImage()
        let expectation = XCTestExpectation(description: "Wait for state change")

        Task {
            await viewModel.startLoading()
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            if case .image = viewModel.state {
                expectation.fulfill()
            } else {
                XCTFail("Expected state to be .image but got \(viewModel.state)")
            }
        }

        await fulfillment(of: [expectation], timeout: 3.0)
    }

    func testStartLoading_withTimeout() async throws {
        networkOperationPerformer.hasInternetConnectionResult = true
        networkOperationPerformer.performNetworkOperationShouldTimeout = true
        let expectation = XCTestExpectation(description: "Wait for state change")

        try await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
        await viewModel.startLoading()

        switch viewModel.state {
        case .error(let message):
            XCTAssertTrue(message.contains("timed"))
        default:
            XCTFail("Expected state to be .error with timeout message but got \(viewModel.state)")
        }

        await fulfillment(of: [expectation], timeout: 3.0)
    }

    func testCancelLoading() async {
        let expectation = XCTestExpectation(description: "Wait for state change")

        Task {
            await viewModel.startLoading()
            viewModel.cancelLoading()
            if case .loading = viewModel.state {
                expectation.fulfill()
            } else {
                XCTFail("Expected state to be .loading but got \(viewModel.state)")
            }
        }

        await fulfillment(of: [expectation], timeout: 1.5)
    }
}
