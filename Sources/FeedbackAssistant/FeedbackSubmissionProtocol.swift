import Foundation

public protocol FeedbackSubmissionProtocol: Sendable {
    func submitFeedback(_ feedback: Feedback) async throws
}