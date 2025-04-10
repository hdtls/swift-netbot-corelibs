//
// See LICENSE.txt for license information
//

import Preference

public enum CleartextDnsServerType: String, CaseIterable, Hashable {

  case system

  case custom

  case mixed
}

extension CleartextDnsServerType: PreferenceRepresentable {}
