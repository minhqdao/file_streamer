# File Streamer Flutter Example

This example demonstrates how to use the `file_streamer` package to pick and upload files using constant-memory streaming in Flutter.

## Platform Setup

### macOS
To allow the app to perform uploads to the internet, you must enable outgoing connections in your App Sandbox:

1. Open `macos/Runner.xcworkspace` in Xcode.
2. Select the **Runner** project in the project navigator.
3. Go to the **Signing & Capabilities** tab.
4. Under **App Sandbox** -> **Network**, check **Outgoing Connections (Client)**.
