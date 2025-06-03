//
// See LICENSE.txt for license information
//

import NIOCore

struct PendingStreamWrite {
  var data: ByteBuffer
  var promise: EventLoopPromise<Void>?
}

/// An result for an IO operation that was done on a non-blocking resource.
@usableFromInline
enum IOResult<T: Equatable>: Equatable {

  /// Signals that the IO operation could not be completed as otherwise we would need to block.
  case wouldBlock(T)

  /// Signals that the IO operation was completed.
  case processed(T)
}

class PendingStreamWritesManager {

  private var pendingWrites = MarkedCircularBuffer<PendingStreamWrite>(initialCapacity: 16)
  internal private(set) var bytes: Int64 = 0

  var isEmpty: Bool {
    if self.pendingWrites.isEmpty {
      assert(self.bytes == 0)
      assert(!self.pendingWrites.hasMark)
      return true
    } else {
      assert(self.bytes >= 0)
      return false
    }
  }

  /// Add a new write and optionally the corresponding promise to the list of outstanding writes.
  func append(_ chunk: PendingStreamWrite) {
    self.pendingWrites.append(chunk)
    self.bytes += numericCast(chunk.data.readableBytes)
  }

  /// Mark the flush checkpoint.
  ///
  /// All writes before this checkpoint will eventually be written to the socket.
  public func markFlushCheckpoint() {
    self.pendingWrites.mark()
  }

  /// Is there a pending flush?
  public var isFlushPending: Bool {
    self.pendingWrites.hasMark
  }

  func write(_ pendingStreamWrites: (MarkedCircularBuffer<PendingStreamWrite>) -> IOResult<Int>) {
    switch pendingStreamWrites(self.pendingWrites) {
    case .processed(var processed):
      self.bytes -= Int64(processed)

      while !self.pendingWrites.isEmpty, processed > 0 {
        guard var pendingWrite = self.pendingWrites.first else {
          break
        }
        if pendingWrite.data.count <= processed {
          _ = self.pendingWrites.removeFirst()
          processed -= pendingWrite.data.count
        } else {
          pendingWrite.data.moveReaderIndex(forwardBy: processed)
          self.pendingWrites[self.pendingWrites.startIndex] = pendingWrite
          processed = 0
        }
      }
    case .wouldBlock:
      fatalError()
    }
  }
}
