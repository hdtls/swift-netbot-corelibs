//
// See LICENSE.txt for license information
//

#if canImport(Network)
  import Network
  import NIOCore
  import NIOTransportServices

  public typealias MultiThreadedEventLoopGroup = NIOTSEventLoopGroup
  typealias DatagramClientBootstrap = NIOTSDatagramBootstrap

  extension DatagramClientBootstrap {

    func connect<Output>(
      to address: SocketAddress,
      channelInitializer: @escaping @Sendable (
        any Channel
      ) -> EventLoopFuture<Output>
    ) async throws -> Output where Output: Sendable {
      try await connect(to: address).flatMap(channelInitializer).get()
    }
  }
#else
  import NIOPosix

  public typealias MultiThreadedEventLoopGroup = NIOPosix.MultiThreadedEventLoopGroup
  typealias DatagramClientBootstrap = DatagramBootstrap
#endif

extension EventLoopGroup where Self == MultiThreadedEventLoopGroup {

  public static var shared: any EventLoopGroup {
    MultiThreadedEventLoopGroup.singleton
  }
}
