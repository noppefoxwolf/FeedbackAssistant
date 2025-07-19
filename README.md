# FeedbackAssistant

A comprehensive Swift package for collecting user feedback in iOS apps with rich attachment support and automatic system information collection.

<img src=".github/screenshot.png" width="300" alt="FeedbackAssistant Interface">

## Features

- 📝 **Easy-to-use feedback collection UI** - Native SwiftUI interface with clean, intuitive design
- 📸 **Automatic screenshot capture** - Capture current screen state with view hierarchy information
- 🗂️ **View hierarchy attachment** - Automatically attach UI debugging information
- 📋 **Multiple feedback types** - Bug Report, Feature Request, Performance Issue, Usability Issue, Other
- 📎 **Rich file attachment support** - Images, documents, and custom files with QuickLook preview
- ℹ️ **Automatic system information** - App version, device info, iOS version automatically collected
- 🌐 **Multi-language support** - English and Japanese localization with String Catalog
- 🎨 **Modern architecture** - Built with SwiftUI, Observation framework, and async/await
- 🔌 **Protocol-based submission** - Flexible integration with any backend service

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/noppefoxwolf/FeedbackAssistant.git", from: "0.0.2")
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
            Button("Send Feedback") {
                showingFeedback = true
            }
        }
        .sheet(isPresented: $showingFeedback) {
            NavigationView {
                FeedbackForm(
                    submitter: YourFeedbackSubmitter()
                )
            }
        }
    }
}
```

### With Automatic Screenshot and View Hierarchy

```swift
import SwiftUI
import FeedbackAssistantUI
import FeedbackAssistant

struct ContentView: View {
    @State private var showingFeedback = false
    
    var body: some View {
        VStack {
            Button("Send Feedback") {
                showingFeedback = true
            }
        }
        .sheet(isPresented: $showingFeedback) {
            NavigationView {
                FeedbackForm(
                    submitter: YourFeedbackSubmitter(),
                    initialFeedback: createFeedbackWithAttachments()
                )
            }
        }
    }
    
    private func createFeedbackWithAttachments() -> Feedback {
        var attachments: [Attachment] = []
        
        // Add screenshot
        if let screenshotAttachment = makeScreenshotAttachment() {
            attachments.append(screenshotAttachment)
        }
        
        // Add view hierarchy
        if let hierarchyAttachment = makeViewHierarchyAttachment() {
            attachments.append(hierarchyAttachment)
        }
        
        return Feedback(attachments: attachments)
    }
    
    private func makeScreenshotAttachment() -> Attachment? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { context in
            window.layer.render(in: context.cgContext)
        }
        
        guard let imageData = image.pngData() else {
            return nil
        }
        
        return Attachment(
            name: "screenshot_\(Date().timeIntervalSince1970).png",
            data: imageData,
            contentType: .png
        )
    }
    
    private func makeViewHierarchyAttachment() -> Attachment? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        let hierarchyDescription = window.perform(Selector(("recursiveDescription")))?.takeUnretainedValue() as? String ?? "Unable to get view hierarchy"
        let hierarchyData = hierarchyDescription.data(using: String.Encoding.utf8) ?? Data()
        
        return Attachment(
            name: "view_hierarchy_\(Date().timeIntervalSince1970).txt",
            data: hierarchyData,
            contentType: .plainText
        )
    }
}
```

### Custom Submission Handler

Implement the `FeedbackSubmitting` protocol to handle feedback submission:

```swift
import FeedbackAssistant

struct YourFeedbackSubmitter: FeedbackSubmitting {
    func submit(_ feedback: Feedback) async throws {
        // Submit feedback to your backend service
        // Handle the feedback data, attachments, etc.
        print("Submitting feedback: \(feedback.title)")
        
        // Example: Send to your API
        try await sendToAPI(feedback)
    }
    
    private func sendToAPI(_ feedback: Feedback) async throws {
        // Your API implementation
    }
}
```

## API Reference

### Components

#### FeedbackForm

The main UI component for collecting feedback with a modern SwiftUI interface.

```swift
public struct FeedbackForm: View {
    public init(
        submitter: FeedbackSubmitting,
        initialFeedback: Feedback = Feedback()
    )
}
```

**Parameters:**
- `submitter`: Object conforming to `FeedbackSubmitting` protocol
- `initialFeedback`: Pre-populated feedback data (optional)

**Usage Note:**
You must wrap `FeedbackForm` in a `NavigationView` when presenting it, as the component relies on navigation features like toolbar items and navigation title.

**Features:**
- 📝 Form fields for title and description
- 🏷️ Feedback type picker with 5 categories
- ℹ️ Automatic system information display
- 📎 Attachment management with QuickLook preview
- 🌐 Multi-language support (English/Japanese)

### Data Models

#### Feedback

Data model representing user feedback with automatic system information collection.

```swift
public struct Feedback: Codable, Identifiable, Sendable {
    public var title: String
    public var description: String
    public var type: FeedbackType
    public var attachments: [Attachment]
    public let systemInfo: SystemInfo
    
    // Methods
    public mutating func attach(_ attachment: Attachment)
    public mutating func detach(_ attachment: Attachment)
}
```

#### Attachment

Data model for file attachments with rich content type support.

```swift
public struct Attachment: Codable, Identifiable, Sendable {
    public let name: String
    public let data: Data
    public let contentType: UTType
    public let createdAt: Date
    
    // Computed properties
    public var fileSize: String
    public var isImage: Bool
    public var isText: Bool
}
```

#### SystemInfo

Automatically collected system information included with every feedback.

```swift
public struct SystemInfo: Codable, Sendable {
    public let appVersion: String
    public let appBuildNumber: String
    public let bundleIdentifier: String
    public let systemVersion: String
    public let deviceModel: String
    public let deviceName: String
    public let systemName: String
}
```

### Enumerations

#### FeedbackType

Enumeration of available feedback types with localized titles.

```swift
public enum FeedbackType: String, CaseIterable, Codable {
    case bug
    case featureRequest
    case performance
    case usability
    case other
    
    public var localizedTitle: String { /* localized titles */ }
}
```

### Protocols

#### FeedbackSubmitting

Protocol for handling feedback submission to your backend service.

```swift
public protocol FeedbackSubmitting: Sendable {
    func submit(_ feedback: Feedback) async throws
}
```

## Localization

FeedbackAssistant supports multiple languages through String Catalog:

- **English** (default)
- **Japanese** (日本語)

To add support for additional languages, add translations to the String Catalog files:
- `Sources/FeedbackAssistant/Resources/Localizable.xcstrings` 
- `Sources/FeedbackAssistantUI/Resources/Localizable.xcstrings`

## Architecture

Built with modern iOS development practices:

- **SwiftUI**: Native declarative UI framework
- **Observation**: Modern reactive programming with `@Observable`
- **Async/Await**: Asynchronous submission handling
- **Protocol-Oriented**: Flexible submission handling
- **String Catalog**: Modern localization approach
- **QuickLook**: Native file preview functionality

## Example App

Check out the `Example.swiftpm` folder for a complete example implementation that demonstrates:
- Automatic screenshot capture
- View hierarchy attachment  
- Custom submission handling
- Japanese localization

## Requirements

- iOS 17.0+
- Swift 6.0+
- Xcode 16.0+

## License

MIT License. See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

