import Foundation
import UIKit

public struct SystemInfo: Codable, Sendable {
    public let appVersion: String
    public let appBuildNumber: String
    public let bundleIdentifier: String
    public let systemVersion: String
    public let deviceModel: String
    public let deviceName: String
    public let systemName: String
    public let createdAt: Date
    
    @MainActor
    public init() {
        let bundle = Bundle.main
        self.appVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        self.appBuildNumber = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        self.bundleIdentifier = bundle.bundleIdentifier ?? "Unknown"
        
        let device = UIDevice.current
        self.systemVersion = device.systemVersion
        self.deviceModel = device.model
        self.deviceName = device.name
        self.systemName = device.systemName
        self.createdAt = Date()
    }
}

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
    public let systemInfo: SystemInfo
    public let createdAt: Date
    public var updatedAt: Date
    
    @MainActor
    public init(
        id: UUID = UUID(),
        title: String = "",
        description: String = "",
        type: FeedbackType = .bug,
        attachments: [Attachment] = [],
        systemInfo: SystemInfo = SystemInfo(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.attachments = attachments
        self.systemInfo = systemInfo
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