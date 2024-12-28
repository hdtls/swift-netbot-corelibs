//
// See LICENSE.txt for license information
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MacrosPlugin: CompilerPlugin {

  var providingMacros: [any Macro.Type] {
    [EditableMacro.self]
  }
}
