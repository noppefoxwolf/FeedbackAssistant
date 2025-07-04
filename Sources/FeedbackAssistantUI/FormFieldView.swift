import SwiftUI

struct FormFieldView: View {
    let title: LocalizedStringKey
    let placeholder: LocalizedStringKey
    @Binding var text: String
    let axis: Axis
    
    init(
        title: LocalizedStringKey,
        placeholder: LocalizedStringKey,
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
            Text(title, bundle: .module)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            TextField(
                "",
                text: $text,
                prompt: Text(placeholder, bundle: .module),
                axis: axis
            )
        }
    }
}