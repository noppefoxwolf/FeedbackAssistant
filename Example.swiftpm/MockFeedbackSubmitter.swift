import FeedbackAssistant

struct MockFeedbackSubmitter: FeedbackSubmitting {
    func submit(_ feedback: Feedback) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        print("Mock submission: \(feedback.title)")
    }
}
