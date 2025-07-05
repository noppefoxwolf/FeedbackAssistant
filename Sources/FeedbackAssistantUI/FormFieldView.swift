import SwiftUI

struct FormFieldView: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let axis: Axis
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        axis: Axis = .horizontal
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.axis = axis
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(0)
            
            TextField(
                title,
                text: $text,
                prompt: Text(placeholder),
                axis: axis
            )
        }
    }
}
