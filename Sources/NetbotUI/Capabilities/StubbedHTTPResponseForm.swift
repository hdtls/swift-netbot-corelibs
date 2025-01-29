//
// See LICENSE.txt for license information
//

import HTTPTypes
import Netbot
import SwiftUI

struct StubbedHTTPResponseForm: View {
  @Binding var data: StubbedHTTPResponse
  @State private var absoluteString: String = ""
  @State private var presentingDataFileImport = false
  @State private var selectedHTTPFieldID: HTTPField.ID?

  #if os(iOS)
    var body: some View {
      Form {
        Section {
          TextField("", text: $data.pattern, prompt: Text("URL Regular Expression"))
        } header: {
          Text("URL Regex")
        }

        Section {

        } header: {
          Text("Data File")
        }

        Section {
          ForEach(data.additionalHTTPFields) { field in
            HStack {
              Text(field.name.rawName)
                .layoutPriority(1)
              Spacer()
              Text(field.value)
            }
          }
          .onDelete { offsets in
            data.additionalHTTPFields.remove(atOffsets: offsets)
          }

          Button("New Field...") {

          }
        } header: {
          Text("Additional HTTP Headers")
        }
      }
    }
  #else
    var body: some View {
      VStack(alignment: .leading) {
        Form {
          TextField("Pattern", text: $data.pattern)
          HStack {
            TextField("File Location", text: $absoluteString)
            Button("Select File") {
              presentingDataFileImport = true
            }
            .fileImporter(
              isPresented: $presentingDataFileImport,
              allowedContentTypes: [.text, .json, .image, .html]
            ) { result in
              switch result {
              case .success(let url):
                data.bodyContentsURL = url
                absoluteString = url.lastPathComponent
              case .failure(let error):
                assertionFailure(error.localizedDescription)
              }
            }
          }
        }

        Text("Additional HTTP Headers")
          .padding(.top)

        Table(data.additionalHTTPFields, selection: $selectedHTTPFieldID) {
          TableColumn("Key", value: \.name.rawName)
          TableColumn("Value", value: \.value)
        }
        HStack {
          Button {

          } label: {
            Image(systemName: "plus")
          }

          Button {
            guard let selectedHTTPFieldID else {
              return
            }
            data.additionalHTTPFields.removeAll(where: { $0.id == selectedHTTPFieldID })
          } label: {
            Image(systemName: "minus")
          }
          .disabled(selectedHTTPFieldID == nil)
        }
      }
      .padding(.horizontal, 32)
      .padding(.vertical)
      .frame(width: 470)
      .onAppear {
        absoluteString =
          data.bodyContentsURL?.isFileURL == true
          ? data.bodyContentsURL!.lastPathComponent : (data.bodyContentsURL?.absoluteString ?? "")
      }
    }
  #endif
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview {
    @Previewable @State var data = StubbedHTTPResponse()
    StubbedHTTPResponseForm(data: $data)
  }
#endif
