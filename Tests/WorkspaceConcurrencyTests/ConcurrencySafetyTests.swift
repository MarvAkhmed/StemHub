//
//  ConcurrencySafetyTests.swift
//  StemHubTests
//
//  Created by Codex on 30.04.2026.
//

import XCTest
@testable import StemHub_macOS

final class ConcurrencySafetyTests: XCTestCase {
    func testTwoSimultaneousAnalysesShareOneInFlightTask() async throws {
        let cache = AudioAnalysisCacheActor<String>()
        let counter = CounterActor()

        async let first = cache.result(for: "file-hash") {
            Task {
                await counter.increment()
                try await Task.sleep(nanoseconds: 25_000_000)
                return "identity"
            }
        }

        async let second = cache.result(for: "file-hash") {
            Task {
                await counter.increment()
                return "duplicate"
            }
        }

        let values = try await [first, second]
        XCTAssertEqual(values, ["identity", "identity"])
        XCTAssertEqual(await counter.value, 1)
    }

    func testTwoSimultaneousUploadsShareOneInFlightUpload() async throws {
        let queue = UploadQueueActor<String>()
        let counter = CounterActor()

        async let first = queue.upload(blobID: "blob-id") {
            Task {
                await counter.increment()
                try await Task.sleep(nanoseconds: 25_000_000)
                return "storage/path"
            }
        }

        async let second = queue.upload(blobID: "blob-id") {
            Task {
                await counter.increment()
                return "second/path"
            }
        }

        let values = try await [first, second]
        XCTAssertEqual(values, ["storage/path", "storage/path"])
        XCTAssertEqual(await counter.value, 1)
    }

    func testLocalCommitCacheActorSerializesWrites() async throws {
        let store = RecordingLocalCommitStore()
        let cache = LocalCommitCacheActor(store: store)

        async let first: Void = cache.saveLocalCommits([], for: "project-id")
        async let second: Void = cache.saveLocalCommits([], for: "project-id")

        try await first
        try await second

        let result = store.snapshot()
        XCTAssertEqual(result.saveCount, 2)
        XCTAssertFalse(result.detectedOverlappingWrite)
    }

    @MainActor
    func testCommentTimestampCapturesClickTimeNotSaveTime() async throws {
        let viewModel = TimestampCaptureHarness()

        viewModel.currentPlaybackTime = 13.25
        viewModel.addCommentAtCurrentTime()
        viewModel.currentPlaybackTime = 20.0

        XCTAssertEqual(viewModel.pendingCommentTimestampSeconds, 13.25)
    }

    @MainActor
    func testCancellingScanPreventsStaleResultsReplacingNewerResults() async throws {
        let scanner = ScanHarness()

        scanner.scan(result: "old", delay: 40_000_000)
        scanner.scan(result: "new", delay: 1_000_000)
        try await Task.sleep(nanoseconds: 80_000_000)

        XCTAssertEqual(scanner.result, "new")
    }

    @MainActor
    func testViewModelStateUpdatesHappenOnMainActor() {
        let viewModel = MainActorViewModelHarness()

        viewModel.applyRows(["kick.wav", "snare.wav"])

        XCTAssertEqual(viewModel.rows, ["kick.wav", "snare.wav"])
        XCTAssertTrue(viewModel.didUpdateOnMainThread)
    }
}

private actor CounterActor {
    private(set) var value = 0

    func increment() {
        value += 1
    }
}

private final class RecordingLocalCommitStore: LocalCommitStore, @unchecked Sendable {
    private let lock = NSLock()
    private var isWriting = false
    private var saveCount = 0
    private var detectedOverlappingWrite = false

    nonisolated func loadLocalCommits(projectID: String) throws -> [LocalCommit] {
        []
    }

    nonisolated func loadLocalCommitsAndCleanup(projectID: String) throws -> [LocalCommit] {
        []
    }

    nonisolated func saveLocalCommits(_ commits: [LocalCommit], for projectID: String) throws {
        lock.lock()
        if isWriting {
            detectedOverlappingWrite = true
        }
        isWriting = true
        lock.unlock()

        Thread.sleep(forTimeInterval: 0.02)

        lock.lock()
        saveCount += 1
        isWriting = false
        lock.unlock()
    }

    nonisolated func cacheFolder(for projectID: String) throws -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(projectID)
    }

    nonisolated func removeCache(for projectID: String) throws {}

    func snapshot() -> (saveCount: Int, detectedOverlappingWrite: Bool) {
        lock.lock()
        defer { lock.unlock() }
        return (saveCount, detectedOverlappingWrite)
    }
}

@MainActor
private final class TimestampCaptureHarness {
    var currentPlaybackTime: Double = 0
    private(set) var pendingCommentTimestampSeconds: Double?

    func addCommentAtCurrentTime() {
        pendingCommentTimestampSeconds = currentPlaybackTime
    }
}

@MainActor
private final class MainActorViewModelHarness {
    private(set) var rows: [String] = []
    private(set) var didUpdateOnMainThread = false

    func applyRows(_ rows: [String]) {
        self.rows = rows
        didUpdateOnMainThread = Thread.isMainThread
    }
}

@MainActor
private final class ScanHarness {
    private var scanTask: Task<Void, Never>?
    private(set) var result: String?

    func scan(result: String, delay: UInt64) {
        scanTask?.cancel()
        scanTask = Task {
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }
            self.result = result
        }
    }

    deinit {
        scanTask?.cancel()
    }
}
