//
// See LICENSE.txt for license information
//

#if os(macOS)
  public import Foundation
  private import os

  extension NSXPCConnection {

    /// Return `remoteObjectProxy` as `any XPCServiceHandleProtocol` if possible.
    ///
    /// If connection remoteObjectProxy is not `XPCServiceHandleProtocol` a notFound error will be throw, otherwise throw error if
    /// `remoteObjectProxyWithErrorHandler` throw error.
    public func service() throws -> any XPCServiceHandleProtocol {
      try remoteObjectProxy(as: (any XPCServiceHandleProtocol).self)
    }

    /// Return `remoteObjectProxy` as `any HelperToolHandleProtocol` if possible.
    ///
    /// If connection remoteObjectProxy is not `HelperToolHandleProtocol` a notFound error will be throw, otherwise throw error if
    /// `remoteObjectProxyWithErrorHandler` throw error.
    public func tool() throws -> any HelperToolHandleProtocol {
      try remoteObjectProxy(as: (any HelperToolHandleProtocol).self)
    }

    private func remoteObjectProxy<Proxy>(as type: Proxy.Type = Proxy.self) throws -> Proxy
    where Proxy: Sendable {
      let remoteObjectProxy =
        remoteObjectProxyWithErrorHandler { error in
          os_log(
            .error, log: .init(subsystem: "com.tenbits.netbot.sbd", category: "com.apple.xpc"),
            "\(error)")
        } as? Proxy
      guard let remoteObjectProxy else {
        throw NEXPCServiceError.notFound
      }
      return remoteObjectProxy
    }
  }

  enum NEXPCServiceError: Error {
    case notFound
  }
#endif
