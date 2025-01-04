//
// See LICENSE.txt for license information
//

public import SwiftUI

public struct SearchableTextFieldStyle: TextFieldStyle {
  @FocusState private var isFocused: Bool
  @Binding public var text: String

  public func _body(configuration: TextField<Self._Label>) -> some View {
    HStack {
      Image(systemName: "magnifyingglass")

      configuration
        .textFieldStyle(.plain)
        .frame(maxWidth: .infinity)
        .foregroundColor(.primary)

      if !text.isEmpty {
        Image(systemName: "xmark")
          .symbolVariant(.circle.fill)
          .onTapGesture {
            text = ""
          }
      }
    }
    .foregroundColor(.secondary)
    .padding(6)
    #if os(iOS)
      .background {
        Color(red: 0.89, green: 0.89, blue: 0.91).opacity(isFocused ? 0.8 : 1)
      }
      .cornerRadius(9)
      .animation(.easeInOut(duration: 0.2), value: isFocused)
    #else
      .cornerRadius(6)
      .focusable()
      .overlay {
        RoundedRectangle(cornerRadius: 6)
        .stroke(Color.accentColor.opacity(0.5), lineWidth: 4)
        .opacity(isFocused ? 1 : 0)
        .scaleEffect(isFocused ? 1 : 1.04)
      }
      .overlay {
        RoundedRectangle(cornerRadius: 6)
        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        .opacity(isFocused ? 0 : 1)
      }
      .animation(isFocused ? .easeIn(duration: 0.2) : .easeOut(duration: 0.0), value: isFocused)
    #endif
    .focused($isFocused)
  }
}

extension TextFieldStyle where Self == SearchableTextFieldStyle {

  public static func searchable(text: Binding<String>) -> SearchableTextFieldStyle {
    SearchableTextFieldStyle(text: text)
  }
}

#if DEBUG
  #Preview {
    SearchableTextFieldStylePreview()
  }

  struct SearchableTextFieldStylePreview: View {
    @State private var text = "HELLO WORLD!"

    var body: some View {
      VStack {
        TextField("", text: $text, prompt: Text("Search"))
          .textFieldStyle(.searchable(text: $text))
          .padding()
      }
    }
  }
#endif
