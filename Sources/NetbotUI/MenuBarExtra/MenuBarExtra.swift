//
// See LICENSE.txt for license information
//

#if os(macOS)
  import Combine
  import Dispatch
  import Netbot
  import SwiftData
  public import SwiftUI
  import Preference

  /// Menu for status item.
  ///
  // +-----------------------------------+
  // | Show Main Window                  |
  // | --------------------------------- |
  // | Outbound Mode                     | -> +-----------------------+
  // | --------------------------------- |    | Direct Mode           |
  // | Policy Group start index 4        |    | ...                   |
  // | Proxy 1                           |    +-----------------------+
  // | ...                               |    | Global Proxy Mode     |
  // | --------------------------------- |    | ...                   |
  // | Policy Group 2                    |    +-----------------------+
  // | Proxy 1                           |    | Rule-Based Proxy Mode |
  // | ...                               |    | ...                   |
  // | --------------------------------- |    +-----------------------+
  // | Top Clients                       |
  // | Top Clients Process 1             |
  // | ...                               |
  // | Top Clients Process 5             |
  // | --------------------------------- |    +-----------------------+
  // | Dashboard                         |    | Enable HTTP Capture   |
  // | --------------------------------- |    | Enable MitM           |
  // | Set as System Proxy               |    | Enable Rewrite        |
  // | --------------------------------- |    | Enable Scripting      |
  // | Capabilities                      | -> +-----------------------+
  // | --------------------------------- |
  // | Switch Profile                    | -> +-----------------------+
  // | --------------------------------- |    | Profile 1             |
  // | Open Netbot Preferences...        |    | ...                   |
  // | --------------------------------- |    +-----------------------+
  // | Quit Netbot                       |
  // +-----------------------------------+
  final public class _MenuBarExtra: NSMenu, @unchecked Sendable {

    @Preference(Prefs.Name.profileURL, store: .applicationGroup)
    private var profileURL = URL.profile

    @Preference(Prefs.Name.enableSystemProxy)
    private var enableSystemProxy = false

    #if ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
      @Preference(Prefs.Name.enableEnhancedMode, store: .applicationGroup)
      private var enableEnhancedMode = false
    #endif

    @Preference(Prefs.Name.enabledHTTPCapabilities, store: .applicationGroup)
    private var enabledHTTPCapabilities: CapabilityFlags = []

    #if EXTENDED_ALL
      @Preference(Prefs.Name.showNetworkConnectivityQualilty)
      private var showConnectivityQuality = true
    #endif

    @Preference(Prefs.Name.maximumNumberOfProcesses)
    private var maximumNumberOfProcesses = 10

    @Preference(Prefs.Name.shouldCollapsePolicyGroupIfThereAreMoreThanFiveItems)
    private var shouldCollapsePolicyGroup = false

    @Preference(Prefs.Name.outboundMode, store: .applicationGroup)
    private var outboundMode: OutboundMode = .direct

    @Preference(Prefs.Name.selectionRecordForGroups, store: .applicationGroup)
    private var selectionRecordForGroups = SelectionRecordForGroups()

    private let profileAssistant = ProfileAssistant.shared

    private var cancellable: Set<AnyCancellable> = .init()

    #if EXTENDED_ALL
      private let processesData = ProcessesEnvironmentKey.defaultValue

      private let nettopItem = NSMenuItem(title: "")
    #endif

    private lazy var outboundModeMenuItem: NSMenuItem = {
      let item = NSMenuItem(title: "Outbound Mode")
      let menu = NSMenu.init(
        title: NSLocalizedString(
          "Outbound Mode",
          comment: "The title of the outbound mode menu"
        )
      )
      menu.items = OutboundMode.allCases.reduce(
        into: [],
        { partialResult, mode in
          let attributedDetailString = NSAttributedString(
            string: "\n" + mode.localizedDescription,
            attributes: [.font: NSFont.systemFont(ofSize: 12)]
          )
          let attributedTitle = NSMutableAttributedString.init(
            string: mode.localizedName.capitalized
          )
          attributedTitle.append(attributedDetailString)

          let item = NSMenuItem.init(
            title: mode.localizedName.capitalized,
            target: self,
            action: #selector(switchOutboundMode(_:))
          )
          item.attributedTitle = attributedTitle
          item.representedObject = mode
          partialResult.append(item)
          partialResult.append(.separator())
        }
      )
      item.submenu = menu
      return item
    }()

    private lazy var capabilitiesMenuItem: NSMenuItem = {
      let capabilitiesMenuItem = NSMenuItem(title: "Capabilities")
      let menu = NSMenu.init(
        title: NSLocalizedString(
          "Capabilities",
          comment: "The title of the capabilities menu"
        )
      )
      menu.items = CapabilityFlags.allCases.map {
        let item = NSMenuItem(
          title: $0.localizedName,
          target: self,
          action: #selector(capabilityFlagsChange(_:))
        )
        item.representedObject = $0
        return item
      }
      capabilitiesMenuItem.submenu = menu
      return capabilitiesMenuItem
    }()

    private lazy var switchProfileMenuItem: NSMenuItem = {
      let switchProfileMenuItem = NSMenuItem(title: "Switch Profile")
      switchProfileMenuItem.submenu = NSMenu(
        title: String(localized: "All Profiles", comment: "The title of the profiles menu"))
      return switchProfileMenuItem
    }()

    private lazy var systemProxyItem: NSMenuItem = {
      NSMenuItem(
        title: "Set as System Proxy", target: self, action: #selector(setAsSystemProxy(_:))
      )
    }()

    #if ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
      private lazy var enhancedModeItem: NSMenuItem = {
        NSMenuItem(
          title: "Enhanced Mode", target: self, action: #selector(enablePacketProcessing(_:))
        )
      }()
    #endif

    @MainActor private lazy var mainWindow = MainWindow()
    @MainActor private lazy var settings = Settings()

    public override init(title: String) {
      super.init(title: title)
      items.append(
        NSMenuItem(title: "Show Main Window", target: self, action: #selector(openWindow(_:)))
      )
      items.append(.separator())

      items.append(outboundModeMenuItem)
      items.append(.separator())

      #if EXTENDED_ALL
        items.append(NSMenuItem(title: "Top Clients"))
        items.append(nettopItem)
        items.append(.separator())
      #endif

      items.append(
        NSMenuItem(title: "Dashboard", target: self, action: #selector(openDashboard(_:))))
      items.append(.separator())

      items.append(systemProxyItem)
      items.append(.separator())

      #if ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
        items.append(enhancedModeItem)
        items.append(.separator())
      #endif

      items.append(capabilitiesMenuItem)
      items.append(.separator())

      items.append(switchProfileMenuItem)
      items.append(.separator())

      items.append(
        NSMenuItem(
          title: "Open \(processName) Preferences...",
          target: self,
          action: #selector(openNetbotPreference(_:)),
          keyEquivalent: ","
        )
      )
      items.append(.separator())

      items.append(
        NSMenuItem(
          title: "Quit \(processName)",
          action: #selector(NSApplication.terminate(_:)),
          keyEquivalent: "q"
        )
      )

      observations()
    }

    public required init(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    private func observations() {
      $outboundMode
        .receive(on: DispatchQueue.main)
        .sink { [weak self] mode in
          guard let self, let submenu = outboundModeMenuItem.submenu else { return }
          for item in submenu.items {
            item.state = item.representedObject as? OutboundMode == mode ? .on : .off
          }
        }
        .store(in: &cancellable)

      #if EXTENDED_ALL
        subscribeProcessesStatus()
      #endif

      $enableSystemProxy
        .receive(on: DispatchQueue.main)
        .map {
          $0 ? NSControl.StateValue.on : .off
        }
        .assign(to: \.state, on: systemProxyItem)
        .store(in: &cancellable)

      #if ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
        $enableEnhancedMode
          .receive(on: DispatchQueue.main)
          .map {
            $0 ? NSControl.StateValue.on : .off
          }
          .assign(to: \.state, on: enhancedModeItem)
          .store(in: &cancellable)
      #endif

      $enabledHTTPCapabilities
        .receive(on: DispatchQueue.main)
        .sink { [weak self] capabilities in
          guard let self, let submenu = capabilitiesMenuItem.submenu else { return }
          for item in submenu.items {
            guard let flag = item.representedObject as? CapabilityFlags else {
              return
            }
            item.state = capabilities.contains(flag) ? .on : .off
          }
        }
        .store(in: &cancellable)

      NotificationCenter.default.publisher(for: ModelContext.didSave)
        .combineLatest($outboundMode, $selectionRecordForGroups, $shouldCollapsePolicyGroup)
        .sink { [weak self] _ in
          guard let self else { return }
          reloadPolicyGroups()
        }
        .store(in: &cancellable)

      Task { @MainActor in
        subscribeProfilesStatus()
      }
    }

    #if EXTENDED_ALL
      private func subscribeProcessesStatus() {
        withObservationTracking {
          _ = processesData.processes
        } onChange: {
          Task { @MainActor in
            // If processes is empty show an empty view instead.
            let numberOfItems = max(self.processes.count, 1)
            self.nettopItem.view = NSHostingView(
              rootView: NettopView(data: Array(self.processes)))
            self.nettopItem.view?.frame = NSRect(
              x: 0,
              y: 0,
              width: 280,
              height: 28 * numberOfItems - 4
            )
            self.itemChanged(self.nettopItem)
            self.subscribeProcessesStatus()
          }
        }
      }
    #endif

    @MainActor private func subscribeProfilesStatus() {
      profileAssistant.profileResource.$profiles
        .combineLatest($profileURL)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] profiles, profileURL in
          guard let self else { return }
          switchProfileMenuItem.submenu?.items = profiles.map {
            let profileMenuItem = NSMenuItem(
              title: $0.name,
              target: self,
              action: #selector(switchProfile(_:))
            )
            profileMenuItem.representedObject = $0.url
            profileMenuItem.state = $0.url == profileURL ? .on : .off
            return profileMenuItem
          }
        }
        .store(in: &cancellable)
    }

    private func reloadPolicyGroups() {
      Task.detached {
        let modelContext = ModelContext(ProfileAssistant.shared.modelContainer)

        var fd = FetchDescriptor<Profile.PersistentModel>()
        fd.relationshipKeyPathsForPrefetching = [\.lazyProxies, \.lazyProxyGroups]
        fd.sortBy = [.init(\.creationDate)]
        guard let profile = try modelContext.fetch(fd).first else {
          return
        }

        let lazyProxies = profile.lazyProxies.sorted(using: KeyPathComparator(\.creationDate)).map(
          \.name)
        var lazyProxyGroups = profile.lazyProxyGroups.sorted(
          using: KeyPathComparator(\.creationDate)
        ).map { AnyProxyGroup(persistentModel: $0) }

        if self.outboundMode == .globalProxy {
          if !lazyProxies.isEmpty || !lazyProxyGroups.isEmpty {
            var lazyProxyGroup = AnyProxyGroup(name: "Global Proxies")
            lazyProxyGroup.lazyProxies = lazyProxies + lazyProxyGroups.map(\.name)
            lazyProxyGroups.insert(lazyProxyGroup, at: 0)
          }
        }

        Task { @MainActor in
          // Remove original items
          self.items.removeAll { $0.representedObject is AnyProxyGroup }

          let outboundMode = self.outboundMode
          let collapsable = self.shouldCollapsePolicyGroup
          let selectionRecordForGroups = self.selectionRecordForGroups

          guard outboundMode != .direct else {
            return
          }

          var groupItems: [NSMenuItem] = []

          for object in lazyProxyGroups {
            let startItem = NSMenuItem(title: object.name, action: nil, keyEquivalent: "")
            startItem.representedObject = object
            startItem.isEnabled = collapsable && object.lazyProxies.count > 5
            groupItems.append(startItem)

            // Items for this group
            let items = object.lazyProxies.map {
              let item = NSMenuItem(
                title: $0,
                target: self,
                action: #selector(self.switchProxy(_:))
              )
              item.representedObject = object

              // Restore selection state
              if let selection = selectionRecordForGroups[object.name], selection == $0 {
                item.state = .on
              } else {
                item.state = .off
              }

              return item
            }

            // Response collapse preference setting.
            if collapsable && object.lazyProxies.count > 5 {
              let submenu = NSMenu()
              submenu.items = items
              startItem.submenu = submenu
            } else {
              groupItems.append(contentsOf: items)
            }

            // Mark that group is end here.
            let endItem = NSMenuItem.separator()
            endItem.representedObject = object
            groupItems.append(endItem)
          }

          self.items.insert(contentsOf: groupItems, at: 4)
        }
      }
    }

    @MainActor @objc public func openWindow(_ sender: Any) {
      openWindow(id: "Main Window")
    }

    @objc private func switchOutboundMode(_ sender: NSMenuItem) {
      dispatchPrecondition(condition: .onQueue(.main))
      guard let mode = sender.representedObject as? OutboundMode else {
        assertionFailure("This should never happen.")
        return
      }
      outboundMode = mode
    }

    @objc private func openDashboard(_ sender: Any) {
      dispatchPrecondition(condition: .onQueue(.main))
      NSWorkspace.shared.openApplication(at: appURL, configuration: .init()) { app, error in
        guard error == nil else {
          assertionFailure(error!.localizedDescription)
          return
        }
      }
    }

    @objc private func setAsSystemProxy(_ sender: NSMenuItem) {
      dispatchPrecondition(condition: .onQueue(.main))
      // We already observer changes of `enableSystemProxy` settings, so there we don't need
      // actual setting action to make duplicated works, instead we just update item state.
      enableSystemProxy = sender.state != .on
    }

    #if ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
      @objc private func enablePacketProcessing(_ sender: NSMenuItem) {
        dispatchPrecondition(condition: .onQueue(.main))
        enableEnhancedMode = sender.state != .on
      }
    #endif

    @objc private func switchProfile(_ sender: NSMenuItem) {
      dispatchPrecondition(condition: .onQueue(.main))
      let url = sender.representedObject as? URL ?? URL.profile
      profileURL = url
    }

    @MainActor @objc public func openNetbotPreference(_ sender: Any) {
      openWindow(id: "com_apple_SwiftUI_Settings_window")
    }

    @objc private func capabilityFlagsChange(_ sender: NSMenuItem) {
      dispatchPrecondition(condition: .onQueue(.main))
      guard let capabilityFlags = sender.representedObject as? CapabilityFlags else {
        return
      }

      sender.state = sender.state == .on ? .off : .on

      if sender.state == .on {
        enabledHTTPCapabilities.insert(capabilityFlags)
      } else {
        enabledHTTPCapabilities.remove(capabilityFlags)
      }
    }

    @objc private func switchProxy(_ sender: NSMenuItem) {
      dispatchPrecondition(condition: .onQueue(.main))
      guard let g = sender.representedObject as? AnyProxyGroup else {
        return
      }
      let name = g.name
      let title = sender.title
      selectionRecordForGroups[name] = title
    }

    @MainActor @IBAction public func openWindow(id: Any) {
      NSApp.setActivationPolicy(.regular)
      NSApp.activate()

      let window: NSWindow
      guard let id = id as? String else { return }

      switch id {
      case "Main Window":
        window = mainWindow
      case "com_apple_SwiftUI_Settings_window":
        window = settings
      default:
        fatalError()
      }

      window.makeKeyAndOrderFront(nil)
      window.center()
    }
  }

  extension NSMenuItem {
    /// Initlaize an instance of `NSMenuItem` with specified title, action and tag.
    ///
    /// Calling this method is equivalent to calling `init(title:action:keyEquivalent:)` with title, action and `""` keyEquivalent, then set tag to specified tag.
    fileprivate convenience init(
      title: String, target: AnyObject? = nil, action: Selector? = nil,
      keyEquivalent charCode: String = ""
    ) {
      self.init(
        title: Bundle.main.localizedString(forKey: title, value: nil, table: nil),
        action: action,
        keyEquivalent: charCode
      )
      self.target = target
    }
  }

  extension NSMenuItem: @retroactive @unchecked Sendable {}

  extension _MenuBarExtra {
    #if EXTENDED_ALL
      private var processes: ArraySlice<ProcessStatistics> {
        processesData.processes.prefix(maximumNumberOfProcesses)
      }
    #endif

    private var processName: String {
      ProcessInfo.processInfo.processName
    }
  }
#endif
