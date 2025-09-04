//
// See LICENSE.txt for license information
//

#if canImport(Darwin)
  import Foundation

  extension URLSession {

    func _download(from url: URL, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> (
      URL, URLResponse
    ) {
      if #available(SwiftStdlib 5.5, *) {
        try await download(from: url, delegate: delegate)
      } else {
        try await withCheckedThrowingContinuation { continuation in
          downloadTask(with: URLRequest(url: url)) { url, response, error in
            guard let url, let response, error == nil else {
              continuation.resume(throwing: error ?? URLError(.badServerResponse))
              return
            }
            continuation.resume(returning: (url, response))
          }
        }
      }
    }
  }
#endif
