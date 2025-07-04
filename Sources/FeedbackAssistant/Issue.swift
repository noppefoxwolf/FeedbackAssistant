import Foundation

public enum FeedbackType: String, CaseIterable, Codable, Sendable {
    case bug = "Bug Report"
    case featureRequest = "Feature Request"
    case performance = "Performance Issue"
    case usability = "Usability Issue"
    case other = "Other"
    
    public var localizedTitle: String {
        switch self {
        case .bug:
            return NSLocalizedString("Bug Report", bundle: .module, comment: "Bug report feedback type")
        case .featureRequest:
            return NSLocalizedString("Feature Request", bundle: .module, comment: "Feature request feedback type")
        case .performance:
            return NSLocalizedString("Performance Issue", bundle: .module, comment: "Performance issue feedback type")
        case .usability:
            return NSLocalizedString("Usability Issue", bundle: .module, comment: "Usability issue feedback type")
        case .other:
            return NSLocalizedString("Other", bundle: .module, comment: "Other feedback type")
        }
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