import SwiftUI
import FeedbackAssistant
import QuickLook

public struct FeedbackAssistantView: View {
    @Environment(\.dismiss)
    private var dismiss
    @State private var issue: Issue
    @State private var isSubmitting = false
    @State private var showingImagePicker = false
    @State private var showingDocumentPicker = false
    @State private var showingActionSheet = false
    @State private var selectedAttachmentURL: URL?
    
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
                basicInformationSection
                descriptionSection
                systemInformationSection
                attachmentsSection
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .confirmationDialog("Add Attachment", isPresented: $showingActionSheet) {
                attachmentDialogContent
            }
            .sheet(isPresented: $showingImagePicker) {
                imagePickerSheet
            }
            .sheet(isPresented: $showingDocumentPicker) {
                documentPickerSheet
            }
            .quickLookPreview($selectedAttachmentURL)
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
    
    
    private var basicInformationSection: some View {
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
    }
    
    private var descriptionSection: some View {
        Section("Description") {
            FormFieldView(
                title: "Please enter the problem and steps to reproduce it",
                placeholder: "Describe the problem, steps to reproduce, expected and actual results",
                text: $issue.description,
                axis: .vertical
            )
        }
    }
    
    private var systemInformationSection: some View {
        Section("System Information") {
            VStack(alignment: .leading, spacing: 8) {
                SystemInfoRow(label: "App Version", value: issue.systemInfo.appVersion)
                SystemInfoRow(label: "Build Number", value: issue.systemInfo.appBuildNumber)
                SystemInfoRow(label: "Bundle ID", value: issue.systemInfo.bundleIdentifier)
                SystemInfoRow(label: "iOS Version", value: issue.systemInfo.systemVersion)
                SystemInfoRow(label: "Device Model", value: issue.systemInfo.deviceModel)
                SystemInfoRow(label: "Device Name", value: issue.systemInfo.deviceName)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    private var attachmentsSection: some View {
        Section("Attachments") {
            Button("Add Attachment") {
                showingActionSheet = true
            }
            
            ForEach(issue.attachments) { attachment in
                attachmentRow(attachment)
            }
        }
    }
    
    private func attachmentRow(_ attachment: Attachment) -> some View {
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
            selectedAttachmentURL = createTempFileForQuickLook(attachment)
        }
        .swipeActions(edge: .trailing) {
            Button("Delete", role: .destructive) {
                removeAttachment(attachment)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
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
    
    @ViewBuilder
    private var attachmentDialogContent: some View {
        Button("Photo Library") {
            showingImagePicker = true
        }
        Button("Files") {
            showingDocumentPicker = true
        }
        Button("Cancel", role: .cancel) {}
    }
    
    @ViewBuilder
    private var imagePickerSheet: some View {
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
    
    @ViewBuilder
    private var documentPickerSheet: some View {
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
    
    
    private func createTempFileForQuickLook(_ attachment: Attachment) -> URL? {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(attachment.name)
        
        do {
            try attachment.data.write(to: tempURL)
            return tempURL
        } catch {
            print("Error writing temporary file: \(error)")
            return nil
        }
    }
    
    private func removeAttachment(_ attachment: Attachment) {
        issue.removeAttachment(attachment)
    }
}

struct SystemInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
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
