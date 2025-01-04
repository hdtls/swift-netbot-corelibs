//
// See LICENSE.txt for license information
//

public import SwiftUI

public struct DashedBorderGroupBoxStyle: GroupBoxStyle {
  @Environment(\.colorScheme) private var colorScheme

  public init() {}

  public func makeBody(configuration: Configuration) -> some View {
    #if os(iOS)
      VStack(alignment: .leading, spacing: 2) {
        Spacer(minLength: 9.2)
        configuration.label
          .padding([.leading], 11.2)
          .font(.subheadline)
        HStack {
          Spacer()
          configuration.content
            .padding(.horizontal, 9)
            .padding(.vertical, 9)
          Spacer()
        }
      }
      .padding(5)
      .background {
        colorScheme == .light ? Color(0xF2F2F7) : Color(0x1C1C1E)
      }
      .cornerRadius(5.5)
      .overlay {
        RoundedRectangle(cornerRadius: 5.5)
          .stroke(
            colorScheme == .light ? Color(0xE0DFDE) : Color(0x3E3D3A),
            style: StrokeStyle(dash: [3])
          )
      }
    #else
      VStack(alignment: .leading, spacing: 3) {
        configuration.label
          .padding(.leading, 10)
          .font(.subheadline)
        VStack {
          configuration.content
        }
        .padding(5)
        .background {
          colorScheme == .light ? Color(0xE7E6E5) : Color(0x353431)
        }
        .cornerRadius(5.5)
        .overlay {
          RoundedRectangle(cornerRadius: 5.5)
            .stroke(
              colorScheme == .light ? Color(0xE0DFDE) : Color(0x3E3D3A),
              style: StrokeStyle(dash: [3])
            )
        }
      }
    #endif
  }
}

extension GroupBoxStyle where Self == DashedBorderGroupBoxStyle {

  /// The dashed border style for group box views.
  public static var dashedBorder: DashedBorderGroupBoxStyle {
    DashedBorderGroupBoxStyle()
  }
}

#Preview {
  HStack {
    GroupBox {
      VStack {
        Rectangle()
          .frame(width: 150, height: 80)

        Rectangle()
          .frame(width: 150, height: 80)
        Spacer()
      }
    } label: {
      Text("HEADER")
        .font(.headline)

      Text("HEADER")
        .font(.headline)
    }
    .groupBoxStyle(DashedBorderGroupBoxStyle())

    GroupBox {
      VStack {
        Rectangle()
          .frame(width: 150, height: 80)

        Rectangle()
          .frame(width: 150, height: 80)

        Spacer()
      }
    } label: {
      Text("HEADER")
        .font(.headline)

      Text("HEADER")
        .font(.headline)
    }
  }
  .padding()
}
