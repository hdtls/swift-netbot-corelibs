// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

#if canImport(SwiftUI)
  import NetbotPreferences
  import SwiftUI

  /// A control that toggles between on and off states of specified capability flag.
  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @_spi(SwiftUI) public struct CapabilitiesToggle<Label>: View where Label: View {

    @AppStorage(Prefs.Name.enabledHTTPCapabilities, store: .__shared)
    private var enabledHTTPCapabilities: CapabilityFlags = []

    private let operand: CapabilityFlags
    private let label: Label

    private var isOn: Binding<Bool> {
      .init {
        enabledHTTPCapabilities.contains(operand)
      } set: {
        if $0 {
          enabledHTTPCapabilities.insert(operand)
        } else {
          enabledHTTPCapabilities.remove(operand)
        }
      }
    }

    public init(
      operand: CapabilityFlags,
      @ViewBuilder label: () -> Label
    ) {
      self.operand = operand
      self.label = label()
    }

    public init(_ titleKey: LocalizedStringKey, operand: CapabilityFlags) where Label == Text {
      self.init(operand: operand) {
        Text(titleKey)
      }
    }

    @_disfavoredOverload
    public init<S>(_ title: S, operand: CapabilityFlags) where S: StringProtocol, Label == Text {
      self.init(operand: operand) {
        Text(title)
      }
    }

    public var body: some View {
      Toggle(isOn: isOn) { label }
    }
  }
#endif
