//
//  TickerViewModel.swift
//  BTCTickerIOSApp
//
//  Created by Matt on 26/10/2025.
//

import Foundation
import Combine
import BTCTicker

@MainActor
final class TickerViewModel: ObservableObject {
    @Published var priceText: String = "--"
    @Published var statusText: String = "Service stopped"
    @Published var isRunning: Bool = false
    @Published var isError: Bool = false

    private let httpClient: HTTPClient
    private let serviceFactory: (HTTPClient) -> TickerService
    private var tickerTask: Task<Void, Never>?
    private var service: TickerService?
    private var lastKnownPrice: Price?

    private let priceFormatter: NumberFormatter
    private let timeFormatter: DateFormatter

    init(httpClient: HTTPClient = URLSessionHTTPClient(),
         serviceFactory: ((HTTPClient) -> TickerService)? = nil) {
        self.httpClient = httpClient
        self.serviceFactory = serviceFactory ?? TickerViewModel.makeDefaultService

        let priceFormatter = NumberFormatter()
        priceFormatter.numberStyle = .currency
        priceFormatter.maximumFractionDigits = 2
        priceFormatter.minimumFractionDigits = 2
        priceFormatter.currencyCode = "USD"
        priceFormatter.currencySymbol = "$"
        self.priceFormatter = priceFormatter

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .medium
        timeFormatter.dateStyle = .none
        self.timeFormatter = timeFormatter
    }

    func start() {
        guard !isRunning else { return }

        tickerTask?.cancel()
        service?.stop()

        let service = serviceFactory(httpClient)
        self.service = service

        if let persisted = service.loadPersisted() {
            lastKnownPrice = persisted
            priceText = format(price: persisted)
        } else if lastKnownPrice == nil {
            priceText = "--"
        }

        isRunning = true
        isError = false
        statusText = "Fetching latest price..."

        tickerTask = Task { [weak self, service] in
            for await state in service.states {
                guard let self else { return }
                self.handle(state: state)
            }
            guard let self else { return }
            self.streamDidFinish()
        }

        service.start()
    }

    func stop() {
        guard isRunning else { return }

        tickerTask?.cancel()
        tickerTask = nil
        service?.stop()
        service = nil

        isRunning = false
        isError = false
        statusText = "Service stopped"
    }

    private func format(price: Price) -> String {
        priceFormatter.currencyCode = price.currency
        if price.currency == "USD" {
            priceFormatter.currencySymbol = "$"
        } else {
            priceFormatter.currencySymbol = price.currency + " "
        }

        return priceFormatter.string(from: NSNumber(value: price.amount)) ?? "\(price.currency) \(price.amount)"
    }

    private func handle(state: TickerState) {
        if let price = state.latest {
            lastKnownPrice = price
            priceText = format(price: price)
        } else if lastKnownPrice == nil {
            priceText = "--"
        }

        if state.isError {
            isError = true
            statusText = state.errorMessage ?? "Unable to fetch price."
        } else {
            isError = false
            if let price = state.latest ?? lastKnownPrice {
                statusText = "Last updated \(timeFormatter.string(from: price.timestamp))"
            } else {
                statusText = "Waiting for price..."
            }
        }
    }

    private func streamDidFinish() {
        guard isRunning else { return }
        isRunning = false
        if !isError {
            statusText = "Service stopped"
        }
    }

    deinit {
        tickerTask?.cancel()
        service?.stop()
    }
}

private extension TickerViewModel {
    static func makeDefaultService(httpClient: HTTPClient) -> TickerService {
        let provider = PriceProviderFactory.makeLiveProvider(httpClient: httpClient)
        return DefaultTickerService(provider: provider)
    }
}
