import SwiftUI
import FeedbackAssistant

public struct FeedbackAssistantView: View {
    @Environment(\.dismiss)
    private var dismiss
    @State private var issue: Issue
    @State private var isSubmitting = false
    
    private let submissionHandler: FeedbackSubmissionProtocol
    private weak var delegate: FeedbackSubmissionDelegate?
    
    public init(
        submissionHandler: FeedbackSubmissionProtocol,
        delegate: FeedbackSubmissionDelegate? = nil,
        initialIssue: Issue = Issue()
    ) {
        self.submissionHandler = submissionHandler
        self.delegate = delegate
        self._issue = State(initialValue: initialIssue)
    }
    
    public var body: some View {
        NavigationView {
            List {
                Section("Basic Information") {
                    FormFieldView(
                        title: "Enter a title that describes your feedback",
                        placeholder: "Example: Cannot make calls from lock screen",
                        text: $issue.title,
                        axis: .vertical
                    )
                    
                    Picker("Feedback Type", selection: $issue.type) {
                        ForEach(FeedbackType.allCases, id: \.self) { type in
                            Text(type.localizedTitle).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Description") {
                    FormFieldView(
                        title: "Please enter the problem and steps to reproduce it",
                        placeholder: "Describe the problem, steps to reproduce, expected and actual results",
                        text: $issue.description,
                        axis: .vertical
                    )
                }
                
                Section("Attachments") {
                    Button("Add Attachment") {
                        addAttachment()
                    }
                    
                    ForEach(issue.attachments) { attachment in
                        HStack {
                            if attachment.isImage, let uiImage = UIImage(data: attachment.data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            } else {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: attachment.isImage ? "photo" : "doc")
                                            .foregroundColor(.secondary)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(attachment.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                Text(attachment.fileSize)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Remove") {
                                removeAttachment(attachment)
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        Task {
                            await submitFeedback()
                        }
                    }
                    .disabled(issue.title.isEmpty || issue.description.isEmpty || isSubmitting)
                }
            }
        }
    }
    
    
    private func submitFeedback() async {
        isSubmitting = true
        delegate?.feedbackSubmissionDidStart()
        
        do {
            try await submissionHandler.submitFeedback(issue)
            delegate?.feedbackSubmissionDidComplete(issue)
            dismiss()
        } catch {
            delegate?.feedbackSubmissionDidFail(issue, error: error)
            isSubmitting = false
        }
    }
    
    private func addAttachment() {
        // TODO: Implement file picker
        let mockData = "Mock file content".data(using: .utf8) ?? Data()
        let mockAttachment = Attachment(
            name: "attachment_\(issue.attachments.count + 1).txt",
            data: mockData,
            contentType: .text
        )
        issue.addAttachment(mockAttachment)
    }
    
    private func removeAttachment(_ attachment: Attachment) {
        issue.removeAttachment(attachment)
    }
}

struct MockFeedbackSubmissionHandler: FeedbackSubmissionProtocol {
    func submitFeedback(_ issue: Issue) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        print("Mock submission: \(issue.title)")
    }
}

#Preview {
    FeedbackAssistantView(
        submissionHandler: MockFeedbackSubmissionHandler(),
        initialIssue: Issue(
            title: "Example Issue",
            description: "This is a pre-filled issue for testing",
            type: .bug,
            attachments: [
                Attachment(
                    name: "screenshot.png",
                    data: Data(),
                    contentType: .png
                )
            ]
        )
    )
}
