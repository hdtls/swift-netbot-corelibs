//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

struct ForwardingRuleForm: View {
  @Binding var data: AnyForwardingRule
  private var disabled = false

  private init(data: Binding<AnyForwardingRule>, disabled: Bool = false) {
    self._data = data
    self.disabled = disabled
  }

  init(data: Binding<AnyForwardingRule>) {
    self._data = data
  }

  var body: some View {
    Form {
      Section {
        #if os(iOS)
          Toggle("Enabled", isOn: $data.isEnabled)
        #endif
        Picker("Type", selection: $data.kind) {
          Section {
            Text(AnyForwardingRule.Kind.domain.rawValue).tag(AnyForwardingRule.Kind.domain)
            Text(AnyForwardingRule.Kind.domainKeyword.rawValue).tag(
              AnyForwardingRule.Kind.domainKeyword)
            Text(AnyForwardingRule.Kind.domainSuffix.rawValue).tag(
              AnyForwardingRule.Kind.domainSuffix)
            Text(AnyForwardingRule.Kind.domainset.rawValue).tag(AnyForwardingRule.Kind.domainset)
          }
          Section {
            Text(AnyForwardingRule.Kind.geoip.rawValue).tag(AnyForwardingRule.Kind.geoip)
            Text(AnyForwardingRule.Kind.ipcidr.rawValue).tag(AnyForwardingRule.Kind.ipcidr)
          }
          Section {
            Text(AnyForwardingRule.Kind.final.rawValue).tag(AnyForwardingRule.Kind.final)
          }
        }
      } footer: {
        promptView
          .accessibilityIdentifier("Rule - Current Kind Summary Label")
          .frame(width: 360, alignment: .leading)
          .fixedSize(horizontal: false, vertical: true)
      }
      .disabled(disabled)

      if data.kind != .final {
        Section {
          TextField(text: $data.value, prompt: Text(expressionPrompt)) {
            Text(expressionTitle)
              .accessibilityIdentifier("Rule - Value Field Label")
          }
          .accessibilityIdentifier("Rule - Value Field")
        } header: {
          #if os(iOS)
            Text(expressionTitle)
              .textCase(.uppercase)
          #endif
        }
        .disabled(disabled)
      }

      Section {
        ProxyPicker("Proxy", selection: $data.foreignKey)
      } header: {
        #if os(iOS)
          Text("Policy")
        #endif
      }
      .disabled(disabled)

      Section {
        TextField("Comment", text: $data.comment, prompt: Text("Comment"))
      } header: {
        #if os(iOS)
          Text("Comment")
        #endif
      }
      .disabled(disabled)

      #if os(macOS)
        Section {
          LabeledContent {
            VStack(alignment: .leading) {
              Toggle(
                "Show a notification when the rule is matched",
                isOn: $data.notification.showNotification)
              TextField(
                "Notification Message", text: $data.notification.message,
                prompt: Text("Notification Message")
              )
              .labelsHidden()
              HStack {
                Text("Show the next notification only after")
                TextField(
                  "Notification Deliver Time Interval",
                  value: $data.notification.timeInterval,
                  format: .number
                )
                .labelsHidden()
                .frame(width: 40)
                Text("seconds")
              }
            }
          } label: {
            Text("Notification")
          }
        }
        .disabled(disabled)
      #endif
    }
    #if os(macOS)
      .fixedSize()
      .padding(.horizontal, 32)
      .padding(.vertical)
    #endif
  }

  private var promptView: AnyView {
    var message: LocalizedStringKey

    switch data.kind {
    case .domain:
      message = "Rule matches if the domain of the request matches precisely."
    case .domainSuffix:
      message =
        "Rule matches if the domain of the request matches the suffix. For example: \"google.com\" matches \"www.google.com\", \"mail.google.com\" and \"google.com\", but does not match \"content-google.com\"."
    case .domainKeyword:
      message = "Rule matches if the domain of the request contains the keyword."
    case .domainset:
      message =
        "A DOMAIN-SET contains multiple sub-rules. Each line in the set is a hostname or an IP address. If the hostname starts with a dot, all sub-domains will be matched."
    case .ruleset:
      message = ""
    case .geoip:
      message =
        "Rule matches if the GeoIP test result matches a specified country code (ISO 3166 Country Codes)."
    case .final:
      message =
        "The FINAL rule defines the default policy for requests witch are not matched by any other rules."
    case .ipcidr:
      message =
        "Rule matches if the IPv4 or IPv6 address of the request matches a specified range."
    }

    return Text(message)
      .frame(alignment: .leading)
      .fixedSize(horizontal: false, vertical: true)
      .foregroundColor(.secondary)
      .eraseToAnyView()
  }

  private var expressionTitle: LocalizedStringKey {
    var title: LocalizedStringKey = "Expression"
    switch data.kind {
    case .domain, .domainSuffix, .domainKeyword:
      title = "Domain"
    case .domainset:
      title = "URL"
    case .ruleset:
      title = "URL"
    case .geoip:
      title = "Country Code"
    case .ipcidr:
      title = "IP Range"
    case .final:
      break
    }
    return title
  }

  private var expressionPrompt: String {
    var prompt: String = ""

    switch data.kind {
    case .domain, .domainSuffix, .domainKeyword:
      prompt = "example.com"
    case .domainset, .ruleset:
      break
    case .geoip:
      break
    case .ipcidr:
      prompt = "IP CIDR block (e.g. 192.168.0.1/24)"
    case .final:
      break
    }

    return prompt
  }

  func disabled(_ disabled: Bool) -> ForwardingRuleForm {
    ForwardingRuleForm(data: $data, disabled: disabled)
  }
}

#if DEBUG
  #Preview {
    BindingPreviewable(AnyForwardingRule()) { $data in
      ForwardingRuleForm(data: $data)
    }
  }

  #Preview("ForwardingRuleForm Disabled") {
    BindingPreviewable(AnyForwardingRule()) { $data in
      ForwardingRuleForm(data: $data)
        .disabled(true)
    }
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview {
    @Previewable @State var data = AnyForwardingRule()
    ForwardingRuleForm(data: $data)
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview("ForwardingRuleForm Disabled") {
    @Previewable @State var data = AnyForwardingRule()
    ForwardingRuleForm(data: $data)
      .disabled(true)
  }
#endif
