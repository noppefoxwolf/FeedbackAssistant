import Foundation

public enum FeedbackType: String, CaseIterable, Codable, Sendable {
    case bug = "Bug Report"
    case featureRequest = "Feature Request"
    case performance = "Performance Issue"
    case usability = "Usability Issue"
    case other = "Other"
    
    public var localizedTitle: String {
        return rawValue
    }
}

public struct Issue: Codable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var description: String
    public var type: FeedbackType
    public var attachments: [Attachment]
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String = "",
        description: String = "",
        type: FeedbackType = .bug,
        attachments: [Attachment] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.attachments = attachments
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public mutating func updateTitle(_ newTitle: String) {
        title = newTitle
        updatedAt = Date()
    }
    
    public mutating func updateDescription(_ newDescription: String) {
        description = newDescription
        updatedAt = Date()
    }
    
    public mutating func addAttachment(_ attachment: Attachment) {
        attachments.append(attachment)
        updatedAt = Date()
    }
    
    public mutating func removeAttachment(_ attachment: Attachment) {
        attachments.removeAll { $0.id == attachment.id }
        updatedAt = Date()
    }
}