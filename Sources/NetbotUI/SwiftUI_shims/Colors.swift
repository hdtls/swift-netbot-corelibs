//
// See LICENSE.txt for license information
//

import SwiftUI

extension Color {

  init(_ hexadecimal: UInt32, opacity: Double = 1) {
    let red = Double((hexadecimal & 0xff0000) >> 16) / 255
    let green = Double((hexadecimal & 0xff00) >> 8) / 255
    let blue = Double((hexadecimal & 0xff) >> 0) / 255
    self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
  }

  static let mayaBlue = Color(0x64D2FF)
}

#Preview {
  ScrollView {
    Color.mayaBlue

    LazyVStack {
      Color.red
      Color.orange
      Color.yellow
      Color.green
      Color.blue
      Color.purple
      Color.pink
      Color.white
      Color.gray
      Color.black
    }

    Color.mint
    Color.teal
    Color.cyan
    Color.indigo
    Color.brown

    Color.primary
    Color.secondary
    Color.accentColor
  }
}
