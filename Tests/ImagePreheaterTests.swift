// The MIT License (MIT)
//
// Copyright (c) 2015-2018 Alexander Grebenyuk (github.com/kean).

import XCTest
import Nuke

class ImagePreheaterTests: XCTestCase {
    var pipeline: MockImagePipeline!
    var preheater: ImagePreheater!
    var observations = [NSKeyValueObservation]()

    override func setUp() {
        super.setUp()

        pipeline = MockImagePipeline()
        preheater = ImagePreheater(pipeline: pipeline)
    }

    // MARK: - Starting Preheating

    func testStartPreheatingWithTheSameRequests() {
        pipeline.queue.isSuspended = true

        // When starting preheating for the same requests (same cacheKey, loadKey).
        expect(pipeline.queue).toFinishWithEnqueuedOperationCount(1)

        let request = Test.request
        preheater.startPreheating(with: [request])
        preheater.startPreheating(with: [request])

        wait()
    }

    func testStartPreheatingWithDifferentProcessors() {
        pipeline.queue.isSuspended = true

        // When starting preheating for the requests with the same URL (same loadKey)
        // but different processors (different cacheKey).
        expect(pipeline.queue).toFinishWithEnqueuedOperationCount(2)

        preheater.startPreheating(with: [Test.request.processed(key: "1") { $0 }])
        preheater.startPreheating(with: [Test.request.processed(key: "2") { $0 }])

        wait()
    }

    func testStartPreheatingSameProcessorsDifferentURLRequests() {
        pipeline.queue.isSuspended = true

        // When starting preheating for the requests with the same URL, but
        // different URL requests (different loadKey) but the same processors
        // (same cacheKey).
        expect(pipeline.queue).toFinishWithEnqueuedOperationCount(2)

        preheater.startPreheating(with: [ImageRequest(urlRequest: URLRequest(url: Test.url, cachePolicy: .returnCacheDataDontLoad, timeoutInterval: 100))])
        preheater.startPreheating(with: [ImageRequest(urlRequest: URLRequest(url: Test.url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 100))])

        wait()
    }

    // MARK: - Stoping Preheating

    func testThatPreheatingRequestsAreStopped() {
        pipeline.queue.isSuspended = true

        let request = Test.request
        _ = expectNotification(MockImagePipeline.DidStartTask, object: pipeline)
        preheater.startPreheating(with: [request])
        wait()

        _ = expectNotification(MockImagePipeline.DidCancelTask, object: pipeline)
        preheater.stopPreheating(with: [request])
        wait()
    }

    func testThatEquaivalentRequestsAreStoppedWithSingleStopCall() {
        pipeline.queue.isSuspended = true

        let request = Test.request
        _ = expectNotification(MockImagePipeline.DidStartTask, object: pipeline)
        preheater.startPreheating(with: [request, request])
        wait()

        _ = expectNotification(MockImagePipeline.DidCancelTask, object: pipeline)
        preheater.stopPreheating(with: [request])

        wait { _ in
            XCTAssertEqual(self.pipeline.createdTaskCount, 1, "")
        }
    }

    func testThatAllPreheatingRequestsAreStopped() {
        pipeline.queue.isSuspended = true

        let request = Test.request
        _ = expectNotification(MockImagePipeline.DidStartTask, object: pipeline)
        preheater.startPreheating(with: [request])
        wait()

        _ = expectNotification(MockImagePipeline.DidCancelTask, object: pipeline)
        preheater.stopPreheating()
        wait()
    }
}
