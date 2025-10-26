## BTCTicker iOS App

### Overview
BTCTicker iOS App is a SwiftUI-based application that presents live Bitcoin pricing updates. It demonstrates a clean architecture where UI state is driven by a view model that coordinates with a ticker service to fetch prices every second. Two primary controls allow users to start and stop streaming updates.

### Features
- **Live streaming** of Bitcoin prices with 1-second updates.
- **Start/Stop controls** to manage the ticker service.
- **Error handling** displays messages while keeping the last known price.
- **Accessible UI** for automated tests and improved usability.

### Dependencies
The app integrates the public [`BTCTicker`](https://github.com/mattpus/BTC-Ticker---TDD-challange) Swift package via Swift Package Manager. The package provides:
- API clients (`RemotePriceProvider`, `URLSessionHTTPClient`)
- Data models (`Price`, `TickerState`, `TickerService`)
- Services (`DefaultTickerService`) for fetching and streaming prices.

### Structure
- `ContentView`: SwiftUI view presenting price, status message, and controls.
- `TickerViewModel`: ObservableObject responsible for formatting and delivering state to the UI.
- `BTCTicker` package: Provides networking, parsing, and ticker service logic.

### Testing
- **Unit tests** (`TickerViewModelTests`) stub the ticker service to validate start/stop and error states.
- **UI tests** (`TickerFlowUITests`) confirm button states and status messaging through the start/stop flow.

To run the suite locally:
```
xcodebuild -scheme BTCTickerIOSAppTests test
xcodebuild -scheme BTCTickerIOSAppUITests test
```
Or execute the test targets directly from Xcode.

### Getting Started
1. Clone this repository.
2. Open `BTCTickerIOSApp.xcodeproj` in Xcode. SPM will automatically resolve the BTCTicker package from GitHub; make sure you have network access for the initial fetch.
3. Build and run the `BTCTickerIOSApp` scheme on an iOS simulator or device.
4. Tap “Start” to begin streaming Bitcoin pricing updates; tap “Stop” to pause.

For network-loss simulation while testing:
- Disable Wi-Fi on the Mac, or
- Use Apple’s Network Link Conditioner (`100% Loss` profile) to simulate offline mode.
