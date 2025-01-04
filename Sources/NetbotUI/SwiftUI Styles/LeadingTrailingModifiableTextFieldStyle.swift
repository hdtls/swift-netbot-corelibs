//
// See LICENSE.txt for license information
//

import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct LeadingTrailingModifiableTextFieldStyle: TextFieldStyle {
  @ViewBuilder private let leading: () -> AnyView
  @ViewBuilder private let trailing: () -> AnyView
  @FocusState private var isFocused: Bool

  init<Leading, Trailing>(
    @ViewBuilder leading: @escaping () -> Leading,
    @ViewBuilder trailing: @escaping () -> Trailing
  ) where Leading: View, Trailing: View {
    self.leading = { AnyView(leading()) }
    self.trailing = { AnyView(trailing()) }
  }

  func _body(configuration: TextField<Self._Label>) -> some View {
    HStack {
      leading()

      configuration
        .textFieldStyle(.plain)
        .frame(maxWidth: .infinity)
        .foregroundColor(.primary)

      trailing()
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

@available(iOS 15.0, macOS 12.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension TextFieldStyle where Self == LeadingTrailingModifiableTextFieldStyle {

  static func leadingTrailingModifiable<Leading, Trailing>(
    @ViewBuilder leading: @escaping () -> Leading,
    @ViewBuilder trailing: @escaping () -> Trailing
  ) -> LeadingTrailingModifiableTextFieldStyle where Leading: View, Trailing: View {
    LeadingTrailingModifiableTextFieldStyle(leading: leading, trailing: trailing)
  }
}

#if DEBUG
  #Preview {
    LeadingTrailingModifiableTextFieldStylePreview()
  }

  struct LeadingTrailingModifiableTextFieldStylePreview: View {
    @State private var text = "HELLO WORLD!"

    var body: some View {
      VStack {
        TextField("", text: $text, prompt: Text("Search"))
          .textFieldStyle(
            .leadingTrailingModifiable {
              Image(systemName: "magnifyingglass")
            } trailing: {
              Button {
                text = ""
              } label: {
                Image(systemName: "xmark")
                  .symbolVariant(.circle.fill)
              }
              .buttonStyle(.plain)
            }
          )
          .padding()
      }
    }
  }
#endif
