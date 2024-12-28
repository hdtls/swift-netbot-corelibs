//
// See LICENSE.txt for license information
//

// swift-format-ignore-file

#if os(Linux) || os(Android)
  #if canImport(Glibc)
    import Glibc
  #elseif canImport(Musl)
    import Musl
  #elseif canImport(Android)
    import Android
  #endif

  #if os(Android)
    private let sysInet_pton:
      @convention(c) (CInt, UnsafePointer<CChar>, UnsafeMutableRawPointer) -> CInt = inet_pton
  #else
    private let sysInet_pton:
      @convention(c) (CInt, UnsafePointer<CChar>?, UnsafeMutableRawPointer?) -> CInt = inet_pton
  #endif
#elseif canImport(Darwin)
  import Darwin

  private let sysInet_pton:
    @convention(c) (CInt, UnsafePointer<CChar>?, UnsafeMutableRawPointer?) -> CInt = inet_pton
#else
  #error("The BSD Socket module was unable to identify your C library.")
#endif

extension StringProtocol {
  public func isIPAddress() -> Bool {
    self.withCString {
      do {
        var ipv4Addr = in_addr()
        try NIOBSDSocket.inet_pton(addressFamily: .inet, addressDescription: $0, address: &ipv4Addr)
        return true
      } catch {
        do {
          var ipv6Addr = in6_addr()
          try NIOBSDSocket.inet_pton(
            addressFamily: .inet6, addressDescription: $0, address: &ipv6Addr)
          return true
        } catch {
          return false
        }
      }
    }
  }
}

private enum NIOBSDSocket {
}

extension NIOBSDSocket {
  /// Specifies the addressing scheme that the socket can use.
  fileprivate struct AddressFamily: RawRepresentable, Sendable {
    public typealias RawValue = CInt
    public var rawValue: RawValue
    public init(rawValue: RawValue) {
      self.rawValue = rawValue
    }
  }
}

// Address Family
extension NIOBSDSocket.AddressFamily {
  /// Address for IP version 4.
  fileprivate static let inet: NIOBSDSocket.AddressFamily =
    NIOBSDSocket.AddressFamily(rawValue: AF_INET)

  /// Address for IP version 6.
  fileprivate static let inet6: NIOBSDSocket.AddressFamily =
    NIOBSDSocket.AddressFamily(rawValue: AF_INET6)

  /// Unix local to host address.
  fileprivate static let unix: NIOBSDSocket.AddressFamily =
    NIOBSDSocket.AddressFamily(rawValue: AF_UNIX)
}

extension NIOBSDSocket {

  @inline(never)
  fileprivate static func inet_pton(
    addressFamily: NIOBSDSocket.AddressFamily,
    addressDescription: UnsafePointer<CChar>,
    address: UnsafeMutableRawPointer
  ) throws {
    switch sysInet_pton(CInt(addressFamily.rawValue), addressDescription, address) {
    case 0: throw IOError(errnoCode: EINVAL, reason: #function)
    case 1: return
    default: throw IOError(errnoCode: errno, reason: #function)
    }
  }
}

/// An `Error` for an IO operation.
private struct IOError: Error {

  /// The actual reason (in an human-readable form) for this `IOError`.
  private var failureDescription: String

  private enum InternalError {
    #if os(Windows)
      case winsock(CInt)
    #endif
    case errno(CInt)
  }

  private let error: InternalError

  /// The `errno` that was set for the operation.
  public var errnoCode: CInt {
    switch self.error {
    case .errno(let code):
      return code
    #if os(Windows)
      default:
        fatalError("IOError domain is not `errno`")
    #endif
    }
  }

  #if os(Windows)
    public init(winsock code: CInt, reason: String) {
      self.error = .winsock(code)
      self.failureDescription = reason
    }
  #endif

  /// Creates a new `IOError``
  ///
  /// - parameters:
  ///     - errorCode: the `errno` that was set for the operation.
  ///     - reason: the actual reason (in an human-readable form).
  public init(errnoCode code: CInt, reason: String) {
    self.error = .errno(code)
    self.failureDescription = reason
  }
}
