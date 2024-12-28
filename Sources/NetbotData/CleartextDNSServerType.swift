//
// See LICENSE.txt for license information
//

public import Preference

public enum CleartextDnsServerType: String, CaseIterable, Hashable {

  case system

  case custom

  case mixed
}

extension CleartextDnsServerType: PreferenceRepresentable {}
