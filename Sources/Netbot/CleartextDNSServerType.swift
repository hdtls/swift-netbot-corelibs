//
// See LICENSE.txt for license information
//

import Preference

@available(SwiftStdlib 5.3, *)
public enum CleartextDnsServerType: String, CaseIterable, Hashable {

  case system

  case custom

  case mixed
}

@available(SwiftStdlib 5.3, *)
extension CleartextDnsServerType: PreferenceRepresentable {}
