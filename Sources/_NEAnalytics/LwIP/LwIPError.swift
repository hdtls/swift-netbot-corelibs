//
// See LICENSE.txt for license information
//

import CNELwIP

public struct LwIPError: Error, Equatable, CustomStringConvertible {

  let code: Int32

  public var description: String {
    switch code {
    case 0: return "Ok."
    case ENOMEM: return "Out of memory error."
    case ENOBUFS: return "Buffer error."
    case EWOULDBLOCK: return "Timeout."
    case EHOSTUNREACH: return "Routing problem."
    case EINPROGRESS: return "Operation in progress."
    case EINVAL: return "Illegal value."
    case EWOULDBLOCK: return "Operation would block."
    case EADDRINUSE: return "Address in use."
    case EALREADY: return "Already connecting."
    case EISCONN: return "Already connected."
    case ENOTCONN: return "Not connected."
    case -1: return "Low-level netif error."
    case ECONNABORTED: return "Connection aborted."
    case ECONNRESET: return "Connection reset."
    case ENOTCONN: return "Connection closed."
    case EIO: return "Illegal argument."
    default: return ""
    }
  }
}
