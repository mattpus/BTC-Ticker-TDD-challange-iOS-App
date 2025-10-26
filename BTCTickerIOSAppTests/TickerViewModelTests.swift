//
//  TickerViewModelTests.swift
//  BTCTickerIOSAppTests
//
//  Created by Matt on 26/10/2025.
//

import Combine
import XCTest
import BTCTicker
@testable import BTCTickerIOSApp

final class TickerViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func test_start_setsRunningStateAndCallsServiceStart() {
        let (sut, service) = makeSUT()

        sut.start()

        XCTAssertTrue(sut.isRunning)
        XCTAssertFalse(sut.isError)
        XCTAssertEqual(sut.statusText, "Fetching latest price...")
        XCTAssertEqual(service.startCallCount, 1)
        XCTAssertEqual(service.stopCallCount, 0)
    }

    func test_start_usesPersistedPriceIfAvailable() {
        let persisted = Price(amount: 42_000, currency: "USD", timestamp: Date())
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.currencyCode = persisted.currency
        formatter.currencySymbol = "$"

        let expectedPrice = formatter.string(from: NSNumber(value: persisted.amount))

        let service = TickerServiceSpy(persisted: persisted)
        let (sut, _) = makeSUT(service: service)

        sut.start()

        XCTAssertEqual(sut.priceText, expectedPrice)
    }

    func test_receivesSuccessfulPriceUpdate() {
        let (sut, service) = makeSUT()
        let price = Price(amount: 43_500.50, currency: "USD", timestamp: Date())
        let updateExpectation = expectation(description: "price updates")

        sut.$priceText
            .dropFirst()
            .sink { value in
                if value.contains("43") {
                    updateExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.start()

        service.send(TickerState(latest: price, isError: false, errorMessage: nil))

        wait(for: [updateExpectation], timeout: 1.0)
        XCTAssertFalse(sut.isError)
        XCTAssertTrue(sut.statusText.contains("Last updated"))
    }

    func test_receivesErrorUpdate() {
        let (sut, service) = makeSUT()
        let errorExpectation = expectation(description: "error updates")

        sut.$statusText
            .dropFirst()
            .sink { value in
                if value == "Network down" {
                    errorExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.start()

        service.send(TickerState(latest: nil, isError: true, errorMessage: "Network down"))

        wait(for: [errorExpectation], timeout: 1.0)
        XCTAssertTrue(sut.isError)
    }

    func test_stop_cancelsStreamingAndCallsServiceStop() {
        let (sut, service) = makeSUT()

        sut.start()
        sut.stop()

        XCTAssertFalse(sut.isRunning)
        XCTAssertFalse(sut.isError)
        XCTAssertEqual(sut.statusText, "Service stopped")
        XCTAssertEqual(service.stopCallCount, 1)
    }

    func test_streamCompletion_resetsRunningFlag() {
        let (sut, service) = makeSUT()
        let completionExpectation = expectation(description: "stream finished")

        sut.$isRunning
            .dropFirst(2) // initial + start()
            .sink { isRunning in
                if !isRunning {
                    completionExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.start()
        service.finish()

        wait(for: [completionExpectation], timeout: 1.0)
        XCTAssertEqual(sut.statusText, "Service stopped")
    }
}

// MARK: - Helpers
private extension TickerViewModelTests {
    func makeSUT(service: TickerServiceSpy? = nil,
                 file: StaticString = #file,
                 line: UInt = #line) -> (TickerViewModel, TickerServiceSpy) {
        let httpClient = HTTPClientStub()
        let serviceSpy = service ?? TickerServiceSpy()
        let sut = TickerViewModel(httpClient: httpClient, serviceFactory: { _ in serviceSpy })
        addTeardownBlock { [weak sut] in
            sut?.stop()
        }
        addTeardownBlock { [weak serviceSpy] in
            serviceSpy?.finish()
        }
        return (sut, serviceSpy)
    }
}

// MARK: - Test Doubles
private final class HTTPClientStub: HTTPClient {
    func get(url: URL, timeout: TimeInterval) async throws -> (Data, HTTPURLResponse) {
        throw URLError(.badServerResponse)
    }
}

private final class TickerServiceSpy: TickerService {
    private let continuation: AsyncStream<TickerState>.Continuation
    private let persisted: Price?

    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0

    let states: AsyncStream<TickerState>

    init(persisted: Price? = nil) {
        self.persisted = persisted
        var localContinuation: AsyncStream<TickerState>.Continuation!
        self.states = AsyncStream { continuation in
            localContinuation = continuation
        }
        self.continuation = localContinuation
    }

    func start() {
        startCallCount += 1
    }

    func stop() {
        stopCallCount += 1
    }

    func loadPersisted() -> Price? {
        persisted
    }

    func send(_ state: TickerState) {
        continuation.yield(state)
    }

    func finish() {
        continuation.finish()
    }
}
