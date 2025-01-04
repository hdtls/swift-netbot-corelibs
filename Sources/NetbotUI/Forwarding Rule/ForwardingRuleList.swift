//
// See LICENSE.txt for license information
//

// swift-format-ignore-file
/*
import Netbot
import SwiftData
import SwiftUI

public struct RuleList: View {
  private var data: [AnyForwardingRule]
  @Bindable private var selection: AnyForwardingRule?
  @Environment(\.modelContext) private var modelContext
  @State private var isFilterEnabled = false
  @State private var selectedFilters = Set<RuleFilter>()
  @State private var editMode: EditMode = .inactive
  @State private var presentingRuleEditor = false
  @State private var forwardingRule = AnyForwardingRule()
  @State private var selectedRules = Set<AnyForwardingRule>()

  private var rules: [AnyForwardingRule] {
    guard isFilterEnabled else {
      return data
    }
    return data.filter {
      // Match one of the filter.
      for filter in selectedFilters {
        if $0.matches(filter) {
          return true
        }
      }
      return false
    }
  }

  public init(_ data: [AnyForwardingRule], selection: AnyForwardingRule?) {
    self._selection = selection
    self._data = data
  }

  public var body: some View {
    Group {
      if editMode.isEditing {
        List(selection: $selectedRules) {
          contents
        }
      } else {
        List(selection: $selection) {
          contents
        }
      }
    }
    .navigationTitle(Text("All Rules"))
    .onChange(of: selectedFilters) {
      // If none Filters selected then the filter should be disabled.
      if selectedFilters.isEmpty {
        isFilterEnabled = false
      }
    }
    .toolbar {
      #if os(iOS)
        ToolbarItem {
          Button {
            editMode = editMode.isEditing ? .inactive : .active
          } label: {
            Text(editMode.isEditing ? "Done" : "Edit")
          }
        }
        ToolbarItemGroup(placement: .bottomBar) {
          toolbarItems
        }
      #else
        toolbarItems
      #endif
    }
    .sheet(isPresented: $presentingRuleEditor) {
      ForwardingRuleEditingSheet(forwardingRule: forwardingRule, container: modelContext.container)
    }
    #if os(iOS)
      .environment(\.editMode, $editMode)
    #else
      .navigationSubtitle(message)
    #endif
  }

  private var contents: some View {
    ForEach(rules) { forwardingRule in
      NavigationLink(value: forwardingRule) {
        RuleCell(data: forwardingRule)
      }
      .moveDisabled(isFilterEnabled)
      .contextMenu {
        if !editMode.isEditing {
          Button(role: .destructive) {
            data.removeAll(where: { $0.id == forwardingRule.id })
          } label: {
            Label("Delete", systemImage: "trash")
          }

          Button {
            self.forwardingRule = forwardingRule
            presentingRuleEditor = true
          } label: {
            Label("Edit", systemImage: "square.and.pencil")
          }
        }
      } preview: {
        ForwardingRuleDetail(data: forwardingRule)
      }
    }
    .onMove { source, destination in
      // TODO: Move Rules from Offsets to Offset
      data.move(fromOffsets: source, toOffset: destination)
    }
    .onDelete { offsets in
      removeRules(atOffsets: offsets)
    }
  }

  #if os(iOS)
    private var message: AnyView {
      guard !editMode.isEditing else {
        return Text(verbatim: "").eraseToAnyView()
      }

      guard isFilterEnabled else {
        return Text("\(rules.count) rules").eraseToAnyView()
      }

      // We do not have enough space to show all Filters, so when there are multiple filters,
      // only the number of filters is shown.
      guard selectedFilters.count == 1 else {
        return Text("\(selectedFilters.count) Filters - (\(Text("\(rules.count) rules")))")
          .eraseToAnyView()
      }

      let filter = selectedFilters.first.unsafelyUnwrapped

      return VStack {
        Text("Filter by:")
        Text(
          "\(Text(filter.strategy.titleKey)) - \(filter.values.first ?? "") (\(Text("\(rules.count) rules")))"
        )
        .font(.footnote)
      }.eraseToAnyView()
    }
  #else
    private var message: Text {
      guard isFilterEnabled else {
        return Text("\(rules.count) rules")
      }

      // We do not have enough space to show all Filters, so when there are multiple filters,
      // only the number of filters is shown.
      if selectedFilters.count == 1 {
        let filter = selectedFilters.first.unsafelyUnwrapped

        return Text(
          "\(Text("Filter by:")) \(Text(filter.strategy.titleKey)) - \(filter.values.first ?? "") (\(Text("\(rules.count) rules")))"
        )
      }
      return Text("\(selectedFilters.count) Filters - (\(Text("\(rules.count) rules")))")
    }
  #endif

  @ViewBuilder private var toolbarItems: some View {
    #if os(iOS)
      if !editMode.isEditing {
        Button {
          if !selectedFilters.isEmpty {
            isFilterEnabled.toggle()
          }
        } label: {
          Image(systemName: "line.3.horizontal.decrease.circle")
            .symbolVariant(isFilterEnabled ? .fill : .none)
        }
        .contextMenu {
          filterItems
        }
      }
      Spacer()
      message
        .font(.footnote)
        .fixedSize()
      Spacer()
      if editMode.isEditing {
        Button(role: .destructive) {
          removeRules(selectedRules)
        } label: {
          Image(systemName: "trash")
        }
        .disabled(selectedRules.isEmpty)
      } else {
        Button {
          forwardingRule = AnyForwardingRule()
          presentingRuleEditor = true
        } label: {
          Image(systemName: "square.and.pencil")
        }
      }
    #else
      Menu {
        filterItems
      } label: {
        Image(systemName: "line.3.horizontal.decrease.circle")
          .symbolVariant(isFilterEnabled ? .fill : .none)
      }
      .menuIndicator(.hidden)
    #endif
  }

  @ViewBuilder private var filterItems: some View {
    Section {
      Text("Edit \(Text("Filters"))")
        .bold()
        .multilineTextAlignment(.center)
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    Section {
      Button {
        isFilterEnabled.toggle()
      } label: {
        Text(isFilterEnabled ? "Disable forwardingRule Filter" : "Enable forwardingRule Filter")
      }
      .disabled(selectedFilters.isEmpty)
    }

    Section {
      ForEach(RuleType.allCases, id: \.self) { type in
        Toggle(
          type.rawValue,
          isOn: Binding {
            selectedFilters.contains(where: {
              $0.strategy == .matchType && $0.values.contains(type.rawValue)
            })
          } set: { newValue, _ in
            let filters = selectedFilters.filter({
              $0.strategy == .matchType && $0.values.contains(type.rawValue)
            })
            if newValue {
              var values: [RuleFilter.Expression] = []
              for filter in filters {
                // remove duplicated items
                selectedFilters.remove(filter)
                values.append(contentsOf: filter.values.filter({ $0 != type.rawValue }))
              }
              values.append(type.rawValue)
              selectedFilters.insert(.init(strategy: .matchType, values: values))
            } else {
              for filter in filters {
                var values = filter.values
                values.removeAll(where: { $0 == type.rawValue })
                selectedFilters.remove(filter)
                if !values.isEmpty {
                  selectedFilters.insert(.init(strategy: .matchType, values: values))
                }
              }
            }
          }
        )
      }
    } header: {
      Text("Type Match")
        .textCase(.uppercase)
    }
  }

  private func removeRules(atOffsets offsets: IndexSet) {
    removeRules(offsets.compactMap { rules.count >= $0 ? rules[$0] : nil })
  }

  private func removeRules<S>(_ rules: S) where S: Sequence, S.Element == AnyForwardingRule {
    let offsets = IndexSet(rules.compactMap(data.firstIndex(of:)))
    data.remove(atOffsets: offsets)
  }
}

public struct RuleCell: View {
  private let data: AnyForwardingRule

  public init(data: AnyForwardingRule) {
    self.data = data
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(data.value)
        .lineLimit(1)
        .truncationMode(.middle)

      HStack {
        Text(data.type.rawValue)
          .padding(.horizontal, 2)
          .padding(.vertical, 1)
          .foregroundColor(.white)
          .background(forwardingRule.color)
          .cornerRadius(2)
          .fixedSize()

        Text(data.policy?.name ?? "-")
      }
      .font(.system(size: 8))
    }
  }
}

extension AnyForwardingRule {

  fileprivate var color: Color {
    switch type {
    case .domain:
      return .yellow
    case .domainSuffix:
      return .purple
    case .domainKeyword:
      return .pink
    case .domainSet:
      return .red
    case .ruleSet:
      return .green
    case .geoIp:
      return .orange
    case .final:
      return .blue
    }
  }
}

extension RuleFilterStrategy {

  var titleKey: LocalizedStringKey {
    switch self {
    case .matchType:
      return "Type"
    case .withKeywords:
      return "Contains"
    }
  }
}

#Preview {
  ModelContainerPreview {
    NavigationStack {
      RuleList(<#T##data: Binding<[AnyForwardingRule]>##Binding<[AnyForwardingRule]>#>, selection: <#T##Binding<AnyForwardingRule?>#>)
    }
  }
}

private struct RuleListPreview: View {
  @State private var data = [
    AnyForwardingRule(AnyRoutingRuleRepresentation("DOMAIN,example.com,DIRECT")!),
    AnyForwardingRule(AnyRoutingRuleRepresentation("DOMAIN-KEYWORD,example,DIRECT")!),
    AnyForwardingRule(AnyRoutingRuleRepresentation("DOMAIN-SET,https://domains.example.com,DIRECT")!),
    AnyForwardingRule(AnyRoutingRuleRepresentation("DOMAIN-SUFFIX,example.com,DIRECT")!),
    AnyForwardingRule(AnyRoutingRuleRepresentation("FINAL,DIRECT")!),
    AnyForwardingRule(AnyRoutingRuleRepresentation("GEOIP,CN,DIRECT")!),
    AnyForwardingRule(AnyRoutingRuleRepresentation("RULE-SET,https://rules.example.com,DIRECT")!),
  ]
  @State private var selection: AnyForwardingRule?

  var body: some View {
    NavigationStack {
      RuleList($data, selection: $selection)
       .subscribeToProfileStatus()
    }
  }
}
*/
