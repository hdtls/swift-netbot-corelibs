//
// See LICENSE.txt for license information
//

import Foundation
import Netbot

protocol URLConvertible {}
extension URL: URLConvertible {}
extension String: URLConvertible {}

extension DownloadProgress {
  @Observable final class Engine: @unchecked Sendable {
    internal private(set) var progress = Progress(totalUnitCount: 0)
    //    private var task: DownloadTask<URL>?
    private let lock = NSLock()

    init() {}

    @discardableResult
    func download(_ convertible: any URLConvertible) async throws -> URL {
      //      let task = AlamofireEnvironmentKey.defaultValue.download(convertible)
      //        .downloadProgress { [weak self] progress in
      //          guard let self else { return }
      //          self.lock.withLock { self.progress = progress }
      //        }
      //        .serializingDownloadedFileURL()
      //      lock.withLock {
      //        self.task = task
      //      }
      //      return try await task.value
      throw URLError(.badURL)
    }

    func cancel() {
      //      lock.withLock {
      //        task?.cancel()
      //        task = nil
      //        progress = .init(totalUnitCount: 0)
      //      }
    }
  }
}
