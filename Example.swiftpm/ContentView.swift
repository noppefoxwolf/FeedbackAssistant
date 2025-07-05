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
            FeedbackForm(
                submitter: MockFeedbackSubmitter(),
                initialFeedback: createFeedbackWithScreenshot()
            )
        }
    }
    
    private func captureScreenshotAndShowFeedback() {
        showingFeedback = true
    }
    
    private func createFeedbackWithScreenshot() -> Feedback {
        var attachments: [Attachment] = []
        
        if let screenshotAttachment = makeScreenshotAttachment() {
            attachments.append(screenshotAttachment)
        }
        
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

struct MockFeedbackSubmitter: FeedbackSubmitting {
    func submit(_ feedback: Feedback) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        print("Mock submission: \(feedback.title)")
    }
}
