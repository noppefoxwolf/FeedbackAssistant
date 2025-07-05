import Foundation

public protocol FeedbackSubmissionProtocol: Sendable {
    func submitFeedback(_ issue: Issue) async throws
}