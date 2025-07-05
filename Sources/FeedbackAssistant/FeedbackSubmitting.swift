import Foundation

public protocol FeedbackSubmitting: Sendable {
    func submit(_ feedback: Feedback) async throws
}