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
                    VStack(alignment: .leading, content: {
                        Text("Enter a title that describes your feedback", bundle: .module)
                        
                        TextField(
                            "",
                            text: $issue.title,
                            prompt: Text("Unable to make phone calls from lock screen", bundle: .module),
                            axis: .vertical
                        )
                    })
                    
                    Picker("Feedback Type", selection: $issue.type) {
                        ForEach(FeedbackType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Description") {
                    VStack(alignment: .leading, content: {
                        Text("Please enter the problem and steps to reproduce it", bundle: .module)
                        
                        TextField(
                            "",
                            text: $issue.description,
                            prompt: Text("Please include the following:\n- Clear description of the problem\n- Step-by-step instructions to reproduce the issue (if possible)\n- Expected result\n- Actual result observed", bundle: .module),
                            axis: .vertical
                        )
                    })
                }
                
                Section("Attachments") {
                    Button("Add Attachment") {
                        addAttachment()
                    }
                    
                    ForEach(issue.attachments, id: \.self) { attachment in
                        HStack {
                            Image(systemName: "paperclip")
                                .foregroundColor(.secondary)
                            Text(attachment)
                                .font(.caption)
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
                    Button(Text("Close", bundle: .module)) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Text("Submit", bundle: .module)) {
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
        let mockAttachment = "attachment_\(issue.attachments.count + 1).txt"
        issue.addAttachment(mockAttachment)
    }
    
    private func removeAttachment(_ attachment: String) {
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
            type: .bug
        )
    )
}
