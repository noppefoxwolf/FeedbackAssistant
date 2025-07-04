import Foundation
import CoreTransferable
import UniformTypeIdentifiers

public struct Attachment: Codable, Identifiable, Sendable, Transferable {
    public let id: UUID
    public let name: String
    public let data: Data
    public let contentType: UTType
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        data: Data,
        contentType: UTType,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.data = data
        self.contentType = contentType
        self.createdAt = createdAt
    }
    
    // MARK: - Transferable Conformance
    
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .data) { attachment in
            attachment.data
        } importing: { data in
            Attachment(
                name: "imported_file",
                data: data,
                contentType: .data
            )
        }
        
        DataRepresentation(contentType: .image) { attachment in
            attachment.data
        } importing: { data in
            Attachment(
                name: "imported_image",
                data: data,
                contentType: .image
            )
        }
        
        DataRepresentation(contentType: .text) { attachment in
            attachment.data
        } importing: { data in
            Attachment(
                name: "imported_text",
                data: data,
                contentType: .text
            )
        }
        
        FileRepresentation(contentType: .item) { attachment in
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(attachment.name)
            try attachment.data.write(to: tempURL)
            return SentTransferredFile(tempURL)
        } importing: { received in
            let data = try Data(contentsOf: received.file)
            let name = received.file.lastPathComponent
            let contentType = UTType(filenameExtension: received.file.pathExtension) ?? .data
            
            return Attachment(
                name: name,
                data: data,
                contentType: contentType
            )
        }
    }
    
    // MARK: - Codable Conformance
    
    private enum CodingKeys: String, CodingKey {
        case id, name, data, contentType, createdAt
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        data = try container.decode(Data.self, forKey: .data)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        let contentTypeString = try container.decode(String.self, forKey: .contentType)
        contentType = UTType(contentTypeString) ?? .data
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(data, forKey: .data)
        try container.encode(contentType.identifier, forKey: .contentType)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

extension Attachment {
    public var fileSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
    }
    
    public var isImage: Bool {
        contentType.conforms(to: .image)
    }
    
    public var isText: Bool {
        contentType.conforms(to: .text)
    }
}