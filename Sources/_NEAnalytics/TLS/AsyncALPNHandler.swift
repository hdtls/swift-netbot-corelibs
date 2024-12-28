//
// See LICENSE.txt for license information
//

import NIOTLS

typealias AsyncALPNHandler = NIOTypedApplicationProtocolNegotiationHandler

/// The error of an ALPN negotiation.
enum ALPNError: Error {

  /// The token of negotiated is unsupported.
  case negotiatedTokenUnsupported(String)
}
