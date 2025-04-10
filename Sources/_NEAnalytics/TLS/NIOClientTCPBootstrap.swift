//
// See LICENSE.txt for license information
//

import Anlzr
import NEAddressProcessing
import NIOCore

extension NIOClientTCPBootstrap {

  /// Enable TLS.
  ///
  /// Set `isEnabled` to `false` has no effect, it define as a walkaround.
  func enableTLS(_ isEnabled: Bool) -> Self {
    guard isEnabled else {
      return self
    }
    return enableTLS()
  }

  func connect<Output>(
    to destination: Address,
    channelInitializer: @escaping @Sendable (any Channel) -> EventLoopFuture<Output>
  ) async throws -> Output where Output: Sendable {
    try await (self.underlyingBootstrap as! ClientBootstrap).connect(
      to: destination, channelInitializer: channelInitializer)
  }
}
