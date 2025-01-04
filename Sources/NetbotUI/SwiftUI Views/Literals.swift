//
// See LICENSE.txt for license information
//

import SwiftUI

struct Literals<Data>: View
where
  Data: RandomAccessCollection & RangeReplaceableCollection & MutableCollection,
  Data.Element: LosslessStringConvertible & Hashable
{
  @Binding var data: Data
  @State private var presentingEditor = false
  @State private var textToAdd = ""
  private var title: Text?
  private var navigationTitle: Text?
  private var prompt: Text?

  init(_ data: Binding<Data>) {
    self._data = data
  }

  private init(_ data: Binding<Data>, title: Text?, navigationTitle: Text?, prompt: Text?) {
    self._data = data
    self.title = title
    self.navigationTitle = navigationTitle
    self.prompt = prompt
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        if let title {
          title
            .textCase(.uppercase)
            .foregroundColor(.secondary)
            .padding([.leading, .trailing])
        }
        Spacer()
        Button {
          presentingEditor = true
        } label: {
          Image(systemName: "plus")
            .symbolVariant(.circle.fill)
            .padding(8)
        }
        .buttonStyle(.plain)
      }
      .background {
        Color.gray.opacity(0.08)
      }

      List {
        ForEach(data, id: \.self) { value in
          Text(value.description)
            .contextMenu {
              Button {
                data.removeAll(where: { $0 == value })
              } label: {
                Text("Delete")
              }

              Button {
                textToAdd = value.description
                presentingEditor = true
              } label: {
                Text("Edit")
              }
            }
        }
        .onDelete { offsets in
          data.remove(atOffsets: offsets)
        }
      }
    }
    .cornerRadius(10)
    .overlay {
      RoundedRectangle(cornerRadius: 10)
        .stroke(.gray.opacity(0.3))
    }
    .sheet(
      isPresented: $presentingEditor,
      onDismiss: {
        textToAdd = ""
      },
      content: {
        NavigationStack {
          VStack(alignment: .leading) {
            TextField("", text: $textToAdd)
              .labelsHidden()
              .frame(width: 450)
              .padding(.vertical, 12)

            if let prompt {
              prompt
                .font(.footnote)
                .lineLimit(nil)
                .foregroundColor(.secondary)
                .padding([.bottom])
                .fixedSize()
            }
          }
          .padding(.horizontal, 24)
          .navigationTitle(navigationTitle ?? Text(verbatim: ""))
          .toolbar {
            toolbarItems
          }
        }
      }
    )
  }

  @ToolbarContentBuilder private var toolbarItems: some ToolbarContent {
    ToolbarItem(placement: .cancellationAction) {
      Button(role: .cancel) {
        presentingEditor = false
      } label: {
        Text("Cancel")
      }
    }

    ToolbarItem(placement: .confirmationAction) {
      Button {
        if !textToAdd.trimmingCharacters(in: .whitespaces).isEmpty {
          if let element = Data.Element.init(textToAdd) {
            data.append(element)
          }
        }
        presentingEditor = false
      } label: {
        Text("Done")
      }
    }
  }
}

extension Literals {

  func title(_ title: Text) -> Self {
    Self($data, title: title, navigationTitle: navigationTitle, prompt: prompt)
  }

  func title(_ titleKey: LocalizedStringKey) -> Self {
    Self($data, title: Text(titleKey), navigationTitle: navigationTitle, prompt: prompt)
  }

  func title<S>(_ title: S) -> Self where S: StringProtocol {
    Self($data, title: Text(title), navigationTitle: navigationTitle, prompt: prompt)
  }

  func navigationTitle(_ navigationTitle: Text) -> Self {
    Self($data, title: title, navigationTitle: navigationTitle, prompt: prompt)
  }

  func navigationTitle(_ navigationTitleKey: LocalizedStringKey) -> Self {
    Self($data, title: title, navigationTitle: Text(navigationTitleKey), prompt: prompt)
  }

  func navigationTitle<S>(_ navigationTitle: S) -> Self where S: StringProtocol {
    Self($data, title: title, navigationTitle: Text(navigationTitle), prompt: prompt)
  }

  func prompt(_ prompt: Text) -> Self {
    Self($data, title: title, navigationTitle: navigationTitle, prompt: prompt)
  }

  func prompt(_ prompt: LocalizedStringKey) -> Self {
    Self($data, title: title, navigationTitle: navigationTitle, prompt: Text(prompt))
  }

  func prompt<S>(_ prompt: S) -> Self where S: StringProtocol {
    Self($data, title: title, navigationTitle: navigationTitle, prompt: Text(prompt))
  }
}

#if DEBUG
  #Preview {
    LiteralsDemo()
  }

  private struct LiteralsDemo: View {
    @State private var data = ["swift.org"]

    var body: some View {
      Literals($data)
        .navigationTitle("New Hostname")
        .padding()
    }
  }
#endif
