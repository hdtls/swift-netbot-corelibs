//
// See LICENSE.txt for license information
//

#if os(macOS) && EXTENDED_ALL
  public import Foundation
  public import class AppKit.NSImage
  public import class AppKit.NSRunningApplication
  public import class AppKit.NSWorkspace

  public struct ProcessStatistics: Hashable, Identifiable, Sendable {

    public struct NetworkStatistics: Hashable, Sendable {
      public var sending: Double = 0
      public var receiving: Double = 0
    }

    public var timestamp: TimeInterval = 0
    public var localizedName: String = ""
    public var processIdentifier: pid_t = 0
    public var bandwidth = NetworkStatistics()
    public var total = NetworkStatistics()

    public var app: NSRunningApplication? {
      NSWorkspace.shared.runningApplications.first {
        $0.processIdentifier == processIdentifier
      }
    }

    public var icon: NSImage {
      app?.icon ?? NSWorkspace.shared.icon(forFile: "/bin/bash")
    }

    public var id: pid_t {
      processIdentifier
    }
  }

  final public class Nettop: @unchecked Sendable {

    /// The download upload and pid_t pairs.
    private var record: [pid_t: ProcessStatistics] = [:]
    private let lock = NSLock()

    public func startListening(
      onQueue queue: DispatchQueue = .main,
      onUpdatePerforming listener: @Sendable @escaping ([ProcessStatistics]) -> Void
    ) {
      DispatchQueue.global().async {
        runAsCommand("nettop -P -x -L 0 -J bytes_in,bytes_out") {
          guard let literal = String(data: $0, encoding: .utf8), !literal.isEmpty else {
            assertionFailure(
              "unable to fetch network activity, please make sure nettop is available"
            )
            return
          }

          self.lock.lock()
          defer { self.lock.unlock() }

          var processes: [ProcessStatistics] = []

          literal.enumerateLines { line, _ in
            guard let process = self.parseLine(line) else {
              return
            }

            processes.append(process)
          }

          processes.sort { lhs, rhs in
            lhs.bandwidth.receiving + lhs.bandwidth.sending > rhs.bandwidth.receiving
              + rhs.bandwidth.sending
          }

          queue.async { [processes] in
            listener(processes)
          }
        }
      }
    }

    private func parseLine(_ text: String) -> ProcessStatistics? {
      // Skip title line
      guard !text.lowercased().contains("bytes_in") else {
        return nil
      }

      // systemstats.118,0,0,
      let components = text.components(separatedBy: ",")
      guard components.count >= 3 else {
        return nil
      }

      let s = components[0].components(separatedBy: ".")
      guard let processIdentifierString = s.last,
        let processIdentifier = pid_t(processIdentifierString)
      else { return nil }

      var process = ProcessStatistics()
      process.timestamp = Date().timeIntervalSince1970
      process.processIdentifier = processIdentifier
      process.localizedName = process.app?.localizedName ?? s.first!
      process.total = .init(
        sending: Double(components[2]) ?? 0,
        receiving: Double(components[1]) ?? 0
      )

      // If record not found just record it's status and ignore this
      // process.
      guard let record = self.record[process.processIdentifier] else {
        self.record[process.processIdentifier] = process
        return nil
      }
      self.record[process.processIdentifier] = process

      // Calculate time interval from last record to current record and
      // this value must greater than .zero
      var timeInterval = process.timestamp - record.timestamp
      timeInterval = max(timeInterval, .zero)
      timeInterval = timeInterval == .zero ? 1 : timeInterval

      process.bandwidth = .init(
        sending: max(process.total.sending - record.total.sending, .zero) / timeInterval,
        receiving: max(process.total.receiving - record.total.receiving, .zero) / timeInterval
      )

      return process
    }
  }
#endif
