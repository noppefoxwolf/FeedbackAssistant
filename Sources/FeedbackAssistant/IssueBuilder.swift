import Foundation
import UIKit

public protocol IssueBuilderModule {
    func buildAttachments() async -> [Attachment]
}

public class IssueBuilder {
    private var modules: [IssueBuilderModule] = []
    
    public init() {}
    
    public func addModule(_ module: IssueBuilderModule) {
        modules.append(module)
    }
    
    public func buildIssue() async -> Issue {
        var attachments: [Attachment] = []
        
        for module in modules {
            let moduleAttachments = await module.buildAttachments()
            attachments.append(contentsOf: moduleAttachments)
        }
        
        return Issue(attachments: attachments)
    }
}

public class ScreenshotCaptureModule: IssueBuilderModule {
    public init() {}
    
    public func buildAttachments() async -> [Attachment] {
        guard let screenshot = await captureScreenshot() else {
            return []
        }
        
        let attachment = Attachment(
            name: "screenshot_\(Date().timeIntervalSince1970).png",
            data: screenshot,
            contentType: .png
        )
        
        return [attachment]
    }
    
    @MainActor
    private func captureScreenshot() -> Data? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { context in
            window.layer.render(in: context.cgContext)
        }
        
        return image.pngData()
    }
}

public class ViewHierarchyCaptureModule: IssueBuilderModule {
    public init() {}
    
    public func buildAttachments() async -> [Attachment] {
        guard let viewHierarchy = await captureViewHierarchy() else {
            return []
        }
        
        let attachment = Attachment(
            name: "view_hierarchy_\(Date().timeIntervalSince1970).txt",
            data: viewHierarchy,
            contentType: .plainText
        )
        
        return [attachment]
    }
    
    @MainActor
    private func captureViewHierarchy() -> Data? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        let hierarchy = buildViewHierarchy(view: window, level: 0)
        return hierarchy.data(using: .utf8)
    }
    
    @MainActor
    private func buildViewHierarchy(view: UIView, level: Int) -> String {
        let indent = String(repeating: "  ", count: level)
        let className = String(describing: type(of: view))
        let frame = view.frame
        let bounds = view.bounds
        
        var result = "\(indent)\(className)\n"
        result += "\(indent)  frame: \(frame)\n"
        result += "\(indent)  bounds: \(bounds)\n"
        result += "\(indent)  alpha: \(view.alpha)\n"
        result += "\(indent)  hidden: \(view.isHidden)\n"
        
        if let backgroundColor = view.backgroundColor {
            result += "\(indent)  backgroundColor: \(backgroundColor)\n"
        }
        
        if view.subviews.count > 0 {
            result += "\(indent)  subviews:\n"
            for subview in view.subviews {
                result += buildViewHierarchy(view: subview, level: level + 2)
            }
        }
        
        return result
    }
}