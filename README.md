# FeedbackAssistant

A Swift package for collecting user feedback in iOS apps with automatic screenshot capture and attachment functionality.

## Features

- 📝 Easy-to-use feedback collection UI
- 📸 Automatic screenshot capture and attachment
- 🎨 Native SwiftUI interface
- 📋 Customizable feedback types (Bug, Feature Request, General)
- 📎 File attachment support
- 🔌 Protocol-based submission handling

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/noppefoxwolf/FeedbackAssistant.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/noppefoxwolf/FeedbackAssistant.git`

## Usage

### Basic Setup

```swift
import SwiftUI
import FeedbackAssistantUI
import FeedbackAssistant

struct ContentView: View {
    @State private var showingFeedback = false
    
    var body: some View {
        VStack {
            Button("Show Feedback") {
                showingFeedback = true
            }
        }
        .sheet(isPresented: $showingFeedback) {
            FeedbackAssistantView(
                submissionHandler: YourFeedbackSubmissionHandler()
            )
        }
    }
}
```

### With Automatic Screenshot

```swift
import SwiftUI
import FeedbackAssistantUI
import FeedbackAssistant

struct ContentView: View {
    @State private var showingFeedback = false
    
    var body: some View {
        VStack {
            Button("Show Feedback") {
                showingFeedback = true
            }
        }
        .sheet(isPresented: $showingFeedback) {
            FeedbackAssistantView(
                submissionHandler: YourFeedbackSubmissionHandler(),
                initialIssue: createIssueWithScreenshot()
            )
        }
    }
    
    private func createIssueWithScreenshot() -> Issue {
        guard let screenshot = captureScreenshot() else {
            return Issue()
        }
        
        let attachment = Attachment(
            name: "screenshot_\(Date().timeIntervalSince1970).png",
            data: screenshot,
            contentType: .png
        )
        
        return Issue(attachments: [attachment])
    }
    
    private func captureScreenshot() -> Data? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { context in
            window.layer.render(in: context.cgContext)
        }
        
        return image.pngData()
    }
}
```

### Custom Submission Handler

Implement the `FeedbackSubmissionProtocol` to handle feedback submission:

```swift
import FeedbackAssistant

class YourFeedbackSubmissionHandler: FeedbackSubmissionProtocol {
    func submitFeedback(_ issue: Issue) async throws {
        // Submit feedback to your backend service
        // Handle the issue data, attachments, etc.
        print("Submitting feedback: \(issue.title)")
        
        // Example: Send to your API
        try await sendToAPI(issue)
    }
    
    private func sendToAPI(_ issue: Issue) async throws {
        // Your API implementation
    }
}
```

## Components

### FeedbackAssistantView

The main UI component for collecting feedback.

**Parameters:**
- `submissionHandler`: Object conforming to `FeedbackSubmissionProtocol`
- `delegate`: Optional delegate for submission events
- `initialIssue`: Pre-populated issue data

### Issue

Data model representing a feedback issue.

**Properties:**
- `title`: Issue title
- `description`: Detailed description
- `type`: Feedback type (bug, feature request, general)
- `attachments`: Array of file attachments

### Attachment

Data model for file attachments.

**Properties:**
- `name`: File name
- `data`: File data
- `contentType`: UTType of the file
- `createdAt`: Creation timestamp

## Example App

Check out the `Example.swiftpm` folder for a complete example implementation.

## Requirements

- iOS 16.0+
- Swift 6.0+
- Xcode 16.0+

## License

MIT License. See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.