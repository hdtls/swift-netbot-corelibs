//
// See LICENSE.txt for license information
//

// swift-format-ignore-file

@attached(member, names: named(profileURL), named(dismiss), named(modelContext), named(profileAssistant), named(data), named(persistentModel), named(init), named(save))
public macro Editable<Data>(data: Data.Type = Data.self) = #externalMacro(module: "NetbotMacros", type: "EditableMacro")
