//
// See LICENSE.txt for license information
//

#if os(macOS)
  import Netbot
  public import SwiftUI

  extension _MenuBarExtra {

    enum LabelStyle: Int, CaseIterable, Hashable {
      case titleAndIcon
      case iconOnly
      case titleOnly

      var localizedName: String {
        switch self {
        case .titleAndIcon:
          return String(localized: "Show icon and rela-time speed")
        case .iconOnly:
          return String(localized: "Show icon only")
        case .titleOnly:
          return String(localized: "Show real-time speed only")
        }
      }
    }

    public struct Label: View {

      @AppStorage(Prefs.Name.enableSystemProxy) private var enableSystemProxy = false

      #if ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
        @AppStorage(Prefs.Name.enableEnhancedMode) private var enableEnhancedMode = false
      #endif

      @AppStorage(Prefs.Name.shouldGrayOutStatusBarItem) private var shouldGrayOutStatusBarItem =
        true

      @AppStorage(Prefs.Name.menuBarExtraTitleLabelStyle)
      private var menuBarExtraTitleLabelStyle: _MenuBarExtra.LabelStyle = .titleAndIcon

      @AppStorage(Prefs.Name.enabledHTTPCapabilities, store: .applicationGroup)
      private var enabledHTTPCapabilities: CapabilityFlags = []

      @State private var rate: String = "0KB/s\n0KB/s"

      public init() {}

      public var body: some View {
        HStack {
          switch menuBarExtraTitleLabelStyle {
          case .titleOnly:
            Text(rate)
              .font(.system(size: 8))
          case .iconOnly:
            Image(systemName: "waveform")
          case .titleAndIcon:
            Image(systemName: "waveform")
            Text(rate)
              .font(.system(size: 8))
          }
        }
        .foregroundStyle(color)
        .bold()
        .fixedSize()
        .modelContainer(ProfileAssistant.shared.modelContainer)
        .subscribeToProfileStatus()
        .subscribeToSystemProxyStatus()
      }

      private var color: Color {
        guard !enabledHTTPCapabilities.contains(.httpsDecryption) else {
          return .red
        }

        #if ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
          guard shouldGrayOutStatusBarItem && !(enableSystemProxy || enableEnhancedMode) else {
            return .primary
          }
        #else
          guard shouldGrayOutStatusBarItem && !enableSystemProxy else {
            return .primary
          }
        #endif
        return .primary.opacity(0.5)
      }
    }
  }
#endif
