//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

private enum Preferences: String, CaseIterable, Codable, Hashable {
  case general = "General"
  case dns = "DNS"
  case appearance = "Appearance"
  case profiles = "Profiles"
  #if os(iOS)
    case advanced = "Advanced"
    case capabilities = "Mapping & Rewriting"
    case license = "License & Updates"
  #endif

  static var allCases: [Preferences] {
    #if os(iOS)
      [.general, .appearance, .dns, .capabilities, .profiles, .license, .advanced]
    #elseif os(macOS)
      [.general, .dns, .appearance, .profiles]
    #else
      []
    #endif
  }
}

extension Preferences {

  #if os(iOS)
    @MainActor @ViewBuilder var label: some View {
      switch self {
      case .general:
        Label("General", systemImage: "gearshape")
      case .dns:
        Label("DNS", systemImage: "network")
      case .appearance:
        Label("Appearance", systemImage: "eye")
          .symbolVariant(.square)
      case .profiles:
        Label("Profiles", systemImage: "filemenu.and.selection")
      case .advanced:
        Label("Advenced", systemImage: "wrench.and.screwdriver")
      case .capabilities:
        Label("Mapping & Rewriting", systemImage: "square.and.pencil")
      case .license:
        Label("License & Updates", systemImage: "square.text.square")
      }
    }
  #endif

  @MainActor @ViewBuilder var body: some View {
    switch self {
    case .general:
      GeneralSettings()
        .navigationTitle(rawValue)
    case .dns:
      DNSSettings()
        .navigationTitle(rawValue)
    case .appearance:
      AppearenceSettings()
        .navigationTitle(rawValue)
    case .profiles:
      ProfileSettings()
        .navigationTitle(rawValue)
    #if os(iOS)
      case .advanced:
        Text(rawValue)
      case .capabilities:
        Text(rawValue)
      case .license:
        Text(rawValue)
    #endif
    }
  }
}

#if os(iOS)
  struct Settings: View {
    var body: some View {
      List {
        ForEach(Preferences.allCases, id: \.self) { preference in
          NavigationLink {
            preference.body
          } label: {
            VStack {
              preference.label
            }
          }
        }
      }
      .navigationTitle("Preferences")
    }
  }

  #if DEBUG
    #Preview {
      PersistentStorePreviewable {
        NavigationStack {
          Settings()
        }
      }
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    #Preview(traits: .persistentStore()) {
      NavigationStack {
        Settings()
      }
    }
  #endif
#elseif os(macOS)
  class Settings: NSWindow {

    private lazy var toolbarProxy = __ToolbarProxy(owner: self)

    convenience init() {
      self.init(
        contentRect: .zero,
        styleMask: [.titled, .fullSizeContentView, .closable],
        backing: .buffered,
        defer: true
      )

      contentView = NSHostingView(
        rootView: Preferences.general.body
          .subscribeOpenURLActions()
          .frame(width: 830)
          .modelContainer(ProfileAssistant.shared.modelContainer)
      )

      let toolbar = NSToolbar()
      toolbar.delegate = toolbarProxy
      self.toolbar = toolbar

      toolbarStyle = .preference

      hasShadow = true
      isReleasedWhenClosed = false

      _setContentView(.init(itemIdentifier: .init(rawValue: Preferences.general.rawValue)))
      toolbar.selectedItemIdentifier = .init(rawValue: Preferences.general.rawValue)
    }

    @objc fileprivate func _setContentView(_ sender: NSToolbarItem) {
      guard let preferences = Preferences(rawValue: sender.itemIdentifier.rawValue) else { return }

      contentView = NSHostingView(
        rootView: preferences.body
          .subscribeOpenURLActions()
          .frame(width: 830)
          .modelContainer(ProfileAssistant.shared.modelContainer)
      )
    }
  }

  extension Settings {

    private class __ToolbarProxy: NSObject, NSToolbarDelegate {

      private weak var owner: Settings?

      init(owner: Settings) {
        self.owner = owner
      }

      func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
      ) -> NSToolbarItem? {
        guard let preferences = Preferences(rawValue: itemIdentifier.rawValue) else {
          return nil
        }

        let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
        toolbarItem.title = preferences.rawValue
        toolbarItem.label = preferences.rawValue
        toolbarItem.target = owner
        toolbarItem.action = #selector(_setContentView(_:))
        switch preferences {
        case .general:
          toolbarItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        case .dns:
          toolbarItem.image = NSImage(systemSymbolName: "network", accessibilityDescription: nil)
        case .appearance:
          toolbarItem.image = NSImage(systemSymbolName: "eye.square", accessibilityDescription: nil)
        case .profiles:
          toolbarItem.image = NSImage(
            systemSymbolName: "filemenu.and.selection", accessibilityDescription: nil)
        }
        return toolbarItem
      }

      func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        Preferences.allCases.map { NSToolbarItem.Identifier(rawValue: $0.rawValue) }
      }

      func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        Preferences.allCases.map { NSToolbarItem.Identifier(rawValue: $0.rawValue) }
      }

      func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        Preferences.allCases.map { NSToolbarItem.Identifier(rawValue: $0.rawValue) }
      }
    }
  }
#endif
