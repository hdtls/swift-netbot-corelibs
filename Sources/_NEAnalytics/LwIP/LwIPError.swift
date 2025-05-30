//
// See LICENSE.txt for license information
//

import CNELwIP

public struct LwIPError: Error, Equatable {
  let code: err_t

  var description: String {
    switch code {
    case ERR_OK: return "Ok."
    case ERR_MEM: return "Out of memory error."
    case ERR_BUF: return "Buffer error."
    case ERR_TIMEOUT: return "Timeout."
    case ERR_RTE: return "Routing problem."
    case ERR_INPROGRESS: return "Operation in progress."
    case ERR_VAL: return "Illegal value."
    case ERR_WOULDBLOCK: return "Operation would block."
    case ERR_USE: return "Address in use."
    case ERR_ALREADY: return "Already connecting."
    case ERR_ISCONN: return "Already connected."
    case ERR_CONN: return "Not connected."
    case ERR_IF: return "Low-level netif error."
    case ERR_ABRT: return "Connection aborted."
    case ERR_RST: return "Connection reset."
    case ERR_CLSD: return "Connection closed."
    case ERR_ARG: return "Illegal argument."
    default: return ""
    }
  }
}
