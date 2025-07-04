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
                issueBuilder: createIssueBuilder()
            )
        }
    }
    
    private func captureScreenshotAndShowFeedback() {
        showingFeedback = true
    }
    
    private func createIssueBuilder() -> IssueBuilder {
        let builder = IssueBuilder()
        builder.addModule(ScreenshotCaptureModule())
        builder.addModule(ViewHierarchyCaptureModule())
        return builder
    }
}

struct MockFeedbackSubmissionHandler: FeedbackSubmissionProtocol {
    func submitFeedback(_ issue: Issue) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        print("Mock submission: \(issue.title)")
    }
}
