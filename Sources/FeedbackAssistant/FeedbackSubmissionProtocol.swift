import Foundation

public protocol FeedbackSubmissionProtocol: Sendable {
    func submitFeedback(_ issue: Issue) async throws
}

public protocol FeedbackSubmissionDelegate: AnyObject {
    func feedbackSubmissionDidStart()
    func feedbackSubmissionDidComplete(_ issue: Issue)
    func feedbackSubmissionDidFail(_ issue: Issue, error: Error)
}