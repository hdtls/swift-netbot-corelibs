//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  private import func Foundation.NSLocalizedString

  extension String {

    public init(
      localized keyAndValue: StaticString, table: String? = nil, comment: String? = nil
    ) {
      self = NSLocalizedString(
        "\(keyAndValue)", tableName: table, bundle: .main, value: "", comment: comment ?? "")
    }
  }
#endif
