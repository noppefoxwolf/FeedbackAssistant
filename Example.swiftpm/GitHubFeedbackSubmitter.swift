import FeedbackAssistant
import Foundation
import UIKit

struct GitHubFeedbackSubmitter: FeedbackSubmitting {
    func submit(_ feedback: FeedbackAssistant.Feedback) async throws {
        let issueBody = createIssueBody(from: feedback)

        try await createGitHubIssue(
            title: feedback.title,
            body: issueBody,
            attachments: feedback.attachments
        )
    }

    private func createIssueBody(from feedback: FeedbackAssistant.Feedback) -> String {
        var body = ""

        if !feedback.description.isEmpty {
            body += "## Description\n\n\(feedback.description)\n\n"
        }

        // Add device information
        body += """
            ## Environment

            - Device: \(feedback.systemInfo.deviceName)
            - iOS Version: \(feedback.systemInfo.systemVersion)
            - App Version: \(feedback.systemInfo.appVersion)
            - Build Number: \(feedback.systemInfo.appBuildNumber)

            """

        // Add attachments information
        if !feedback.attachments.isEmpty {
            body += "## Attachments\n\n"
            for attachment in feedback.attachments {
                body += "- \(attachment.name)\n"
            }
            body += "\n"
        }

        return body
    }

    private func createGitHubIssue(title: String, body: String, attachments: [Attachment])
        async throws
    {
        let owner = "<customization owner>"
        let repo = "<customization repo>"
        let token = ProcessInfo.processInfo.environment["GITHUB_TOKEN"] ?? ""

        guard !token.isEmpty else {
            throw GitHubError.missingToken
        }

        // Upload attachments first
        var uploadedAttachments: [String] = []
        for attachment in attachments {
            if let uploadedUrl = try await uploadAttachment(
                attachment,
                owner: owner,
                repo: repo,
                token: token
            ) {
                let markdownLink =
                    isImageFile(attachment.name)
                    //? "<img src=\"\(uploadedUrl)\" width=\"300\" alt=\"\(attachment.name)\">"
                    ? "![\(attachment.name)](\(uploadedUrl))"
                    : "[\(attachment.name)](\(uploadedUrl))"
                uploadedAttachments.append(markdownLink)
            }
        }

        // Add uploaded attachments to body
        var finalBody = body
        if !uploadedAttachments.isEmpty {
            finalBody += "\n\n## Uploaded Attachments\n\n"
            finalBody += uploadedAttachments.joined(separator: "\n\n")
        }

        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/issues")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let issueData: [String: Any] = [
            "title": title,
            "body": finalBody,
            "labels": ["bug", "feedback"],
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: issueData)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }

        guard httpResponse.statusCode == 201 else {
            throw GitHubError.createFailed(statusCode: httpResponse.statusCode)
        }

        // Parse the response to get the issue URL
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let issueUrl = json["html_url"] as? String
        {
            print("Issue created: \(issueUrl)")
        }
    }

    private func uploadAttachment(
        _ attachment: Attachment,
        owner: String,
        repo: String,
        token: String
    ) async throws -> String? {
        // Get data from Transferable attachment
        let attachmentData = attachment.data

        // Create a unique filename
        let filename = "\(UUID().uuidString)_\(attachment.name)"

        // Upload to GitHub as a file in the repository
        let uploadUrl = URL(
            string: "https://api.github.com/repos/\(owner)/\(repo)/contents/attachments/\(filename)"
        )!
        var request = URLRequest(url: uploadUrl)
        request.httpMethod = "PUT"
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let base64Content = attachmentData.base64EncodedString()
        let uploadData: [String: Any] = [
            "message": "Upload attachment for issue",
            "content": base64Content,
            "branch": "main",
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: uploadData)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }

        guard httpResponse.statusCode == 201 else {
            throw GitHubError.uploadFailed(statusCode: httpResponse.statusCode)
        }

        // Parse response to get download URL
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = json["content"] as? [String: Any],
            let downloadUrl = content["download_url"] as? String
        {
            return downloadUrl
        }

        return nil
    }

    private func isImageFile(_ filename: String) -> Bool {
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "webp", "svg"]
        let fileExtension = filename.lowercased().components(separatedBy: ".").last ?? ""
        return imageExtensions.contains(fileExtension)
    }
}

enum GitHubError: LocalizedError {
    case missingToken
    case invalidResponse
    case createFailed(statusCode: Int)
    case uploadFailed(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "GitHub token is missing. Please set GITHUB_TOKEN environment variable."
        case .invalidResponse:
            return "Invalid response from GitHub API."
        case .createFailed(let statusCode):
            return "Failed to create issue. Status code: \(statusCode)"
        case .uploadFailed(let statusCode):
            return "Failed to upload attachment. Status code: \(statusCode)"
        }
    }
}
