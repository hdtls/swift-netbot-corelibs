//
// See LICENSE.txt for license information
//

import SwiftUI

struct PickLiteralButton<Label>: View where Label: View {
  @State private var presentingEditor = false

  private let textField: TextField<Text>
  private let prompt: Text?
  private let label: Label
  private let onCompletion: () -> Void
  private var navigationTitle: Text?

  private init(
    textField: TextField<Text>, label: Label, prompt: Text?, navigationTitle: Text?,
    onCompletion: @escaping () -> Void
  ) {
    self.textField = textField
    self.label = label
    self.prompt = prompt
    self.navigationTitle = navigationTitle
    self.onCompletion = onCompletion
  }

  init(
    text: Binding<String>, prompt: Text? = nil,
    @ViewBuilder label: () -> Label, onCompletion: @escaping () -> Void
  ) {
    self.textField = .init("", text: text)
    self.prompt = prompt
    self.label = label()
    self.onCompletion = onCompletion
  }

  @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
  init<F>(
    value: Binding<F.FormatInput?>, format: F, prompt: Text? = nil,
    @ViewBuilder label: () -> Label, onCompletion: @escaping () -> Void
  ) where F: ParseableFormatStyle, F.FormatOutput == String {
    self.textField = .init("", value: value, format: format)
    self.prompt = prompt
    self.label = label()
    self.onCompletion = onCompletion
  }

  @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
  init<F>(
    value: Binding<F.FormatInput>, format: F, prompt: Text? = nil,
    @ViewBuilder label: () -> Label, onCompletion: @escaping () -> Void
  ) where F: ParseableFormatStyle, F.FormatOutput == String {
    self.textField = .init("", value: value, format: format)
    self.prompt = prompt
    self.label = label()
    self.onCompletion = onCompletion
  }

  var body: some View {
    Button {
      presentingEditor = true
    } label: {
      label
    }
    .sheet(isPresented: $presentingEditor) {
      NavigationStack {
        VStack(alignment: .leading) {
          textField
            .labelsHidden()
            .frame(width: 450)
            .padding(.vertical, 12)

          if let prompt {
            prompt
              .font(.footnote)
              .foregroundColor(.secondary)
              .padding([.bottom])
          }
        }
        .padding(.horizontal, 24)
        .navigationTitle(navigationTitle ?? Text(verbatim: ""))
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", role: .cancel) {
              presentingEditor = false
            }
          }

          ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
              onCompletion()
              presentingEditor = false
            }
          }
        }
      }
    }
  }
}

extension PickLiteralButton where Label == Text {
  init(
    _ titleKey: LocalizedStringKey, text: Binding<String>, prompt: Text? = nil,
    onCompletion: @escaping () -> Void
  ) {
    self.textField = .init("", text: text)
    self.prompt = prompt
    self.label = Text(titleKey)
    self.onCompletion = onCompletion
  }

  init<S>(
    _ title: S, text: Binding<String>, prompt: Text? = nil, navigationTitle: S,
    onCompletion: @escaping () -> Void
  ) where S: StringProtocol {
    self.textField = .init("", text: text)
    self.prompt = prompt
    self.label = Text(title)
    self.onCompletion = onCompletion
  }

  @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
  init<F>(
    _ titleKey: LocalizedStringKey, value: Binding<F.FormatInput?>, format: F, prompt: Text? = nil,
    onCompletion: @escaping () -> Void
  ) where F: ParseableFormatStyle, F.FormatOutput == String {
    self.textField = .init("", value: value, format: format)
    self.prompt = prompt
    self.label = Text(titleKey)
    self.onCompletion = onCompletion
  }

  @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
  init<F>(
    _ titleKey: LocalizedStringKey, value: Binding<F.FormatInput>, format: F, prompt: Text? = nil,
    onCompletion: @escaping () -> Void
  ) where F: ParseableFormatStyle, F.FormatOutput == String {
    self.textField = .init("", value: value, format: format)
    self.prompt = prompt
    self.label = Text(titleKey)
    self.onCompletion = onCompletion
  }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension PickLiteralButton where Label == SwiftUI.Label<Text, Image> {
  init(
    _ titleKey: LocalizedStringKey, systemImage: String, text: Binding<String>, prompt: Text? = nil,
    onCompletion: @escaping () -> Void
  ) {
    self.textField = .init("", text: text)
    self.prompt = prompt
    self.label = SwiftUI.Label(titleKey, systemImage: systemImage)
    self.onCompletion = onCompletion
  }

  @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
  init<F>(
    _ titleKey: LocalizedStringKey, systemImage: String, value: Binding<F.FormatInput?>, format: F,
    prompt: Text? = nil, onCompletion: @escaping () -> Void
  ) where F: ParseableFormatStyle, F.FormatOutput == String {
    self.textField = .init("", value: value, format: format)
    self.prompt = prompt
    self.label = SwiftUI.Label(titleKey, systemImage: systemImage)
    self.onCompletion = onCompletion
  }

  @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
  init<F>(
    _ titleKey: LocalizedStringKey, systemImage: String, value: Binding<F.FormatInput>, format: F,
    prompt: Text? = nil, onCompletion: @escaping () -> Void
  ) where F: ParseableFormatStyle, F.FormatOutput == String {
    self.textField = .init("", value: value, format: format)
    self.prompt = prompt
    self.label = SwiftUI.Label(titleKey, systemImage: systemImage)
    self.onCompletion = onCompletion
  }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension PickLiteralButton where Label == SwiftUI.Label<Text, Image> {
  init(
    _ titleKey: LocalizedStringKey, image: ImageResource, text: Binding<String>,
    prompt: Text? = nil, onCompletion: @escaping () -> Void
  ) {
    self.textField = .init("", text: text)
    self.prompt = prompt
    self.label = SwiftUI.Label(titleKey, image: image)
    self.onCompletion = onCompletion
  }

  init<F>(
    _ titleKey: LocalizedStringKey, image: ImageResource, value: Binding<F.FormatInput?>, format: F,
    prompt: Text? = nil, onCompletion: @escaping () -> Void
  ) where F: ParseableFormatStyle, F.FormatOutput == String {
    self.textField = .init("", value: value, format: format)
    self.prompt = prompt
    self.label = SwiftUI.Label(titleKey, image: image)
    self.onCompletion = onCompletion
  }

  init<F>(
    _ titleKey: LocalizedStringKey, image: ImageResource, value: Binding<F.FormatInput>, format: F,
    prompt: Text? = nil, onCompletion: @escaping () -> Void
  ) where F: ParseableFormatStyle, F.FormatOutput == String {
    self.textField = .init("", value: value, format: format)
    self.prompt = prompt
    self.label = SwiftUI.Label(titleKey, image: image)
    self.onCompletion = onCompletion
  }
}

extension PickLiteralButton {
  func navigationTitle(_ title: Text) -> Self {
    Self(
      textField: textField, label: label, prompt: prompt, navigationTitle: title,
      onCompletion: onCompletion)
  }

  func navigationTitle(_ titleKey: LocalizedStringKey) -> Self {
    Self(
      textField: textField, label: label, prompt: prompt, navigationTitle: Text(titleKey),
      onCompletion: onCompletion)
  }

  func navigationTitle<S>(_ title: S) -> Self where S: StringProtocol {
    Self(
      textField: textField, label: label, prompt: prompt, navigationTitle: Text(title),
      onCompletion: onCompletion)
  }
}
