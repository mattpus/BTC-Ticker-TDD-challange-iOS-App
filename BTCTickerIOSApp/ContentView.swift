//
//  ContentView.swift
//  BTCTickerIOSApp
//
//  Created by Matt on 26/10/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TickerViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Text("Bitcoin Ticker")
                .font(.title)
                .bold()
                .accessibilityIdentifier("titleLabel")

            Text(viewModel.priceText)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(viewModel.isError ? Color.red : Color.primary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .accessibilityIdentifier("priceLabel")

            Text(viewModel.statusText)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(viewModel.isError ? Color.red : Color.secondary)
                .accessibilityIdentifier("statusLabel")

            HStack(spacing: 16) {
                Button(action: viewModel.start) {
                    Label("Start", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isRunning)
                .accessibilityIdentifier("startButton")

                Button(action: viewModel.stop) {
                    Label("Stop", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.isRunning)
                .accessibilityIdentifier("stopButton")
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
