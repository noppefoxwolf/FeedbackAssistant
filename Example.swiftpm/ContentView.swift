import SwiftUI
import FeedbackAssistantUI
import FeedbackAssistant

struct ContentView: View {
    @State private var showingFeedback = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
            
            Button("Send Feedback") {
                captureScreenshotAndShowFeedback()
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $showingFeedback) {
            FeedbackAssistantView(
                submissionHandler: MockFeedbackSubmissionHandler(),
                initialIssue: createIssueWithScreenshot()
            )
        }
    }
    
    private func captureScreenshotAndShowFeedback() {
        showingFeedback = true
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

struct MockFeedbackSubmissionHandler: FeedbackSubmissionProtocol {
    func submitFeedback(_ issue: Issue) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        print("Mock submission: \(issue.title)")
    }
}
