import SwiftUI
import FeedbackAssistant

public struct FeedbackAssistantView: View {
    @Environment(\.dismiss)
    private var dismiss
    @State private var issue: Issue
    @State private var isSubmitting = false
    @State private var showingImagePicker = false
    @State private var showingDocumentPicker = false
    @State private var showingActionSheet = false
    @State private var selectedAttachment: Attachment?
    
    private let submissionHandler: FeedbackSubmissionProtocol
    private weak var delegate: FeedbackSubmissionDelegate?
    
    public init(
        submissionHandler: FeedbackSubmissionProtocol,
        delegate: FeedbackSubmissionDelegate? = nil,
        issueBuilder: IssueBuilder? = nil
    ) {
        self.submissionHandler = submissionHandler
        self.delegate = delegate
        
        if let issueBuilder = issueBuilder {
            self._issue = State(initialValue: Issue())
            Task {
                let builtIssue = await issueBuilder.buildIssue()
                await MainActor.run {
                    self.issue = builtIssue
                }
            }
        } else {
            self._issue = State(initialValue: Issue())
        }
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
                        showingActionSheet = true
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
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedAttachment = attachment
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Delete", role: .destructive) {
                                removeAttachment(attachment)
                            }
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
            .confirmationDialog("Add Attachment", isPresented: $showingActionSheet) {
                Button("Photo Library") {
                    showingImagePicker = true
                }
                Button("Files") {
                    showingDocumentPicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker { image in
                    if let imageData = image.pngData() {
                        let attachment = Attachment(
                            name: "image_\(Date().timeIntervalSince1970).png",
                            data: imageData,
                            contentType: .png
                        )
                        issue.addAttachment(attachment)
                    }
                }
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker { url in
                    do {
                        let data = try Data(contentsOf: url)
                        let name = url.lastPathComponent
                        let contentType = UTType(filenameExtension: url.pathExtension) ?? .data
                        
                        let attachment = Attachment(
                            name: name,
                            data: data,
                            contentType: contentType
                        )
                        issue.addAttachment(attachment)
                    } catch {
                        print("Error loading file: \(error)")
                    }
                }
            }
            .fullScreenCover(item: $selectedAttachment) { attachment in
                AttachmentPreviewView(attachment: attachment) {
                    selectedAttachment = nil
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
    
    
    private func removeAttachment(_ attachment: Attachment) {
        issue.removeAttachment(attachment)
    }
}

struct AttachmentPreviewView: View {
    let attachment: Attachment
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                if attachment.isImage, let uiImage = UIImage(data: attachment.data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if attachment.isText, let text = String(data: attachment.data, encoding: .utf8) {
                    ScrollView {
                        Text(text)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .background(Color(.systemBackground))
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary)
                        
                        Text(attachment.name)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                        
                        Text(attachment.fileSize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .background(attachment.isImage ? Color.black : Color(.systemBackground))
            .navigationTitle(attachment.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

import UIKit
import UniformTypeIdentifiers

struct ImagePicker: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageSelected(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentSelected: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.onDocumentSelected(url)
            }
        }
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
