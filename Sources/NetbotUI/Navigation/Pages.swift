//
// See LICENSE.txt for license information
//

import SwiftUI

enum Pages: String, Codable, Hashable {
  #if EXTENDED_ALL
    case activity
    case process
    case device
  #endif
  case policy
  case forwardingRule
  case httpCapture = "http-capture"
  case httpsDecryption = "https-decryption"
  case httpRewrite = "http-rewrite"
  case dashboard
  case settings
}

extension Pages {

  @ViewBuilder var label: some View {
    switch self {
    #if EXTENDED_ALL
      case .activity:
        Label("Activity", systemImage: "waveform.path.ecg")
      case .process:
        Label("Process", systemImage: "apple.terminal")
      case .device:
        Label("Device", systemImage: "macbook.and.iphone")
    #endif
    case .policy:
      Label("Policy", systemImage: "server.rack")
    case .forwardingRule:
      Label("Rule", systemImage: "list.dash")
    case .httpCapture:
      Label("HTTP Capture", systemImage: "dot.circle.viewfinder")
    case .httpsDecryption:
      Label("HTTPS MitM", systemImage: "lock")
        .symbolVariant(.circle)
    case .httpRewrite:
      Label("HTTP Rewrite", systemImage: "applescript")
    case .dashboard:
      Label("Dashboard", systemImage: "ladybug")
    case .settings:
      Label("Settings", systemImage: "gearshape")
    }
  }

  @MainActor @ViewBuilder var body: some View {
    switch self {
    #if EXTENDED_ALL
      case .activity:
        #if os(macOS)
          ComposedActivities()
        #endif
      case .process:
        #if os(macOS)
          ProcessesPage()
        #endif
      case .device:
        #if os(macOS)
          DevicesPage()
        #endif
    #endif
    case .policy:
      PoliciesPage()
    case .forwardingRule:
      ForwardingRulesPage()
    case .httpCapture:
      ContentCapturePage()
    case .httpsDecryption:
      #if os(macOS)
        HTTPSDecryptionPage()
      #endif
    case .httpRewrite:
      HTTPRewritesPage()
    case .dashboard:
      #if os(macOS)
        ContentUnavailableView(
          "Replace with embbed Dashboard application", systemImage: "exclamationmark"
        )
        .symbolVariant(.circle)
      #endif
    case .settings:
      #if os(macOS)
        ContentUnavailableView("Replace with Settings", systemImage: "exclamationmark")
          .symbolVariant(.circle)
      #endif
    }
  }
}
