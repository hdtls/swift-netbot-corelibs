//
// See LICENSE.txt for license information
//

#if os(macOS)
  import SwiftUI
  import UniformTypeIdentifiers
  import AppKit

  struct PathControl: NSViewRepresentable {

    typealias NSViewType = NSPathControl

    @Binding private var url: URL
    private let allowedTypes: [UTType]?
    private let action: (URL?) -> Void

    init(url: Binding<URL>, allowedTypes: [UTType]? = nil, action: @escaping (URL?) -> Void) {
      self._url = url
      self.allowedTypes = allowedTypes
      self.action = action
    }

    func makeNSView(context: Context) -> NSPathControl {
      let control = NSPathControl()
      control.allowedTypes = allowedTypes?.map { $0.identifier }
      control.target = context.coordinator
      control.action = #selector(Coordinator.eventHandler)
      return control
    }

    func updateNSView(_ nsView: NSPathControl, context: Context) {
      nsView.isEnabled = context.environment.isEnabled
      nsView.url = url
      if nsView.pathItems.count > 3 {
        for item in nsView.pathItems[1...nsView.pathItems.count - 3] {
          item.title = ""
        }
      }
    }

    func makeCoordinator() -> Coordinator {
      Coordinator(control: self)
    }

    class Coordinator: NSObject, NSPathControlDelegate {
      private let control: PathControl

      init(control: PathControl) {
        self.control = control
      }

      @MainActor @objc func eventHandler(sender: NSPathControl) {
        control.action(sender.clickedPathItem?.url)
      }
    }
  }

  #if DEBUG
    #Preview {
      PathControl(url: .constant(URL(fileURLWithPath: #filePath))) { _ in

      }
    }
  #endif
#endif
