//
// See LICENSE.txt for license information
//

#if os(macOS)
  public import Foundation

  /// Helper function to run shell script and observe update with specified args and handler
  /// - Parameters:
  ///   - args: The args used by shell script
  ///   - onUpdatePerforming: The update handler
  /// - Returns: The progress created to run this shell
  @discardableResult
  public func runAsCommand(_ args: String..., onUpdatePerforming: (@Sendable (Data) -> Void)? = nil)
    -> Process
  {
    let process = Process()

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()

    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.arguments = ["-c"] + args

    stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
      onUpdatePerforming?(handle.availableData)
    }

    do {
      try process.run()
      process.waitUntilExit()
    } catch {
      print("shell pipe executed with error", error)
    }

    return process
  }
#endif
