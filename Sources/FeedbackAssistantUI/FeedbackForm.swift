import SwiftUI
import FeedbackAssistant
import QuickLook
import _QuickLook_SwiftUI
import Observation

@Observable
@MainActor
class FeedbackViewModel {
    var feedback: Feedback
    var isSubmitting = false
    var showingImagePicker = false
    var showingDocumentPicker = false
    var showingActionSheet = false
    var selectedAttachmentURL: URL?
    var showingErrorAlert = false
    var errorMessage = ""
    
    init(initialFeedback: Feedback = Feedback()) {
        self.feedback = initialFeedback
    }
    
    func attach(_ attachment: Attachment) {
        feedback.attach(attachment)
    }
    
    func detach(_ attachment: Attachment) {
        feedback.detach(attachment)
    }
    
    func makeTempFile(for attachment: Attachment) -> URL? {
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
}

public struct FeedbackForm: View {
    @Environment(\.dismiss)
    private var dismiss
    @State private var viewModel: FeedbackViewModel
    
    private let submitter: FeedbackSubmitting
    
    public init(
        submitter: FeedbackSubmitting,
        initialFeedback: Feedback = Feedback()
    ) {
        self.submitter = submitter
        self._viewModel = State(initialValue: FeedbackViewModel(initialFeedback: initialFeedback))
    }
    
    public var body: some View {
        NavigationView {
            List {
                basicInformationSection
                descriptionSection
                systemInformationSection
                attachmentsSection
            }
            .navigationTitle(String(localized: "Feedback", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .confirmationDialog(String(localized: "Add Attachment", bundle: .module), isPresented: $viewModel.showingActionSheet) {
                attachmentDialogContent
            }
            .sheet(isPresented: $viewModel.showingImagePicker) {
                imagePickerSheet
            }
            .sheet(isPresented: $viewModel.showingDocumentPicker) {
                documentPickerSheet
            }
            .quickLookPreview($viewModel.selectedAttachmentURL)
            .alert(String(localized: "Error", bundle: .module), isPresented: $viewModel.showingErrorAlert) {
                Button(String(localized: "OK", bundle: .module)) {
                    viewModel.showingErrorAlert = false
                }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    
    private func submit() async {
        viewModel.isSubmitting = true
        
        do {
            try await submitter.submit(viewModel.feedback)
            dismiss()
        } catch {
            viewModel.errorMessage = error.localizedDescription
            viewModel.showingErrorAlert = true
            viewModel.isSubmitting = false
        }
    }
    
    
    private var basicInformationSection: some View {
        Section("Basic Information") {
            FormFieldView(
                title: String(localized: "Enter a title that describes your feedback", bundle: .module),
                placeholder: String(localized: "App crashes when tapping share", bundle: .module),
                text: $viewModel.feedback.title,
                axis: .vertical
            )
            
            Picker(String(localized: "Feedback Type", bundle: .module), selection: $viewModel.feedback.type) {
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
                title: String(localized: "Please enter the problem and steps to reproduce it", bundle: .module),
                placeholder: String(localized: "Tap share → app crashes", bundle: .module),
                text: $viewModel.feedback.description,
                axis: .vertical
            )
        }
    }
    
    private var systemInformationSection: some View {
        Section("System Information") {
            VStack(alignment: .leading, spacing: 8) {
                SystemInfoRow(label: String(localized: "App Version", bundle: .module), value: viewModel.feedback.systemInfo.appVersion)
                SystemInfoRow(label: String(localized: "Build Number", bundle: .module), value: viewModel.feedback.systemInfo.appBuildNumber)
                SystemInfoRow(label: String(localized: "Bundle ID", bundle: .module), value: viewModel.feedback.systemInfo.bundleIdentifier)
                SystemInfoRow(label: String(localized: "iOS Version", bundle: .module), value: viewModel.feedback.systemInfo.systemVersion)
                SystemInfoRow(label: String(localized: "Device Model", bundle: .module), value: viewModel.feedback.systemInfo.deviceModel)
                SystemInfoRow(label: String(localized: "Device Name", bundle: .module), value: viewModel.feedback.systemInfo.deviceName)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    private var attachmentsSection: some View {
        Section("Attachments") {
            Button(String(localized: "Add Attachment", bundle: .module)) {
                viewModel.showingActionSheet = true
            }
            
            ForEach(viewModel.feedback.attachments) { attachment in
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
            viewModel.selectedAttachmentURL = viewModel.makeTempFile(for: attachment)
        }
        .swipeActions(edge: .trailing) {
            Button(String(localized: "Delete", bundle: .module), role: .destructive) {
                viewModel.detach(attachment)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(String(localized: "Close", bundle: .module)) {
                dismiss()
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(String(localized: "Submit", bundle: .module)) {
                Task {
                    await submit()
                }
            }
            .disabled(viewModel.feedback.title.isEmpty || viewModel.feedback.description.isEmpty || viewModel.isSubmitting)
        }
    }
    
    @ViewBuilder
    private var attachmentDialogContent: some View {
        Button(String(localized: "Photo Library", bundle: .module)) {
            viewModel.showingImagePicker = true
        }
        Button(String(localized: "Files", bundle: .module)) {
            viewModel.showingDocumentPicker = true
        }
        Button(String(localized: "Cancel", bundle: .module), role: .cancel) {}
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
                viewModel.attach(attachment)
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
                viewModel.attach(attachment)
            } catch {
                print("Error loading file: \(error)")
            }
        }
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

struct MockFeedbackSubmitter: FeedbackSubmitting {
    func submit(_ feedback: Feedback) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        print("Mock submission: \(feedback.title)")
    }
}

#Preview {
    FeedbackForm(
        submitter: MockFeedbackSubmitter(),
        initialFeedback: Feedback(
            title: "Example Feedback",
            description: "This is a pre-filled feedback for testing",
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
