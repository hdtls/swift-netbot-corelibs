//
// See LICENSE.txt for license information
//

import NIOTLS

@available(SwiftStdlib 5.3, *)
typealias AsyncALPNHandler = NIOTypedApplicationProtocolNegotiationHandler

/// The error of an ALPN negotiation.
@available(SwiftStdlib 5.3, *)
enum ALPNError: Error {

  /// The token of negotiated is unsupported.
  case negotiatedTokenUnsupported(String)
}
