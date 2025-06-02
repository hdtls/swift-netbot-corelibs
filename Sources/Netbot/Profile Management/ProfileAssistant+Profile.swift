//
// See LICENSE.txt for license information
//

import Logging
import RegexBuilder
import _ProfileSupport

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import FoundationInternationalization
  import class Foundation.OperationQueue
#else
  import Foundation
#endif

@available(swift 5.9)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension ProfileAssistant {

  public func insert(_ profile: Profile) async throws {
    try await withCheckedThrowingContinuation { continuation in
      let data = profile.formatted()
      let writeIntent = NSFileAccessIntent.writingIntent(with: profile.url)
      let coordinator = NSFileCoordinator(filePresenter: filePresenter)
      coordinator.coordinate(with: [writeIntent], queue: .init()) { error in
        do {
          if let error {
            throw error
          }
          try data.write(to: writeIntent.url, atomically: true, encoding: .utf8)
          continuation.resume()
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }

    // Update profile resource if profile inserted into same directory as `profileURL`.
    guard profile.url.deletingLastPathComponent() == self.profilesDirectory else {
      return
    }

    await Task { @MainActor in
      let profileInfo = ProfileInfo(
        url: profile.url,
        numberOfRules: profile.lazyForwardingRules.count,
        numberOfProxies: profile.lazyProxies.count
      )
      var profiles = profileResource.profiles
      profiles.append(profileInfo)
      profiles.sort(using: KeyPathComparator(\.name))
      profileResource.profiles = profiles
    }.value
  }

  public func replace<Replacement>(
    _ keyPath: KeyPath<Profile, Replacement>, with replacement: Replacement
  ) async throws {
    var field: Profile.FormatStyle.Fields?

    var mutableReplacementString = "\(replacement)"

    switch keyPath {
    case \.logLevel:
      field = .logLevel
      mutableReplacementString = (replacement as! Logger.Level).rawValue
    case \.dnsSettings.servers:
      field = .dnsServers
      mutableReplacementString = (replacement as! [String]).joined(separator: ",")
    case \.exceptions:
      field = .exceptions
      mutableReplacementString = (replacement as! [String]).joined(separator: ",")
    case \.httpListenAddress:
      field = .httpListenAddress
    case \.httpListenPort:
      field = .httpListenPort
      if let port = (replacement as! Int?) {
        mutableReplacementString = "\(port)"
      } else {
        mutableReplacementString = ""
      }
    case \.socksListenAddress:
      field = .socksListenAddress
    case \.socksListenPort:
      field = .socksListenPort
      if let port = (replacement as! Int?) {
        mutableReplacementString = "\(port)"
      } else {
        mutableReplacementString = ""
      }
    case \.excludeSimpleHostnames:
      field = .excludeSimpleHostnames
    case \.skipCertificateVerification:
      field = .skipCertificateVerification
    case \.hostnames:
      field = .hostnames
      mutableReplacementString = (replacement as! [String]).joined(separator: ",")
    case \.base64EncodedP12String:
      field = .base64EncodedP12String
    case \.passphrase:
      field = .passphrase
    case \.testURL:
      field = .testURL
      if let url = (replacement as! URL?) {
        mutableReplacementString = "\(url)"
      } else {
        mutableReplacementString = ""
      }
    case \.testTimeout:
      field = .testTimeout
    case \.proxyTestURL:
      field = .proxyTestURL
      if let url = (replacement as! URL?) {
        mutableReplacementString = "\(url)"
      } else {
        mutableReplacementString = ""
      }
    case \.dontAlertRejectErrors:
      field = .dontAlertRejectErrors
    case \.dontAllowRemoteAccess:
      field = .dontAllowRemoteAccess
    default:
      break
    }

    guard let field else {
      return
    }

    let replacementString = mutableReplacementString

    try await modify { readIntent, writeIntent in
      let file = try String(contentsOf: readIntent.url, encoding: .utf8)
      let originalLines = file.split(separator: .newlineSequence, omittingEmptySubsequences: false)
      var hasMached = false

      var lines: [Substring] = try originalLines.compactMap {
        let regex = try Regex("^ *\(field.rawValue) *= *.+")
        if !$0.matches(of: regex).isEmpty {
          hasMached = true
          if replacementString.isEmpty {
            // Remove field if replacement is emppty.
            return nil
          } else {
            return $0.replacing(regex, with: "\(field.rawValue) = \(replacementString)")
          }
        }
        return $0
      }

      guard lines == originalLines else {
        // Save changes to file.
        try lines
          .joined(separator: "\n")
          .write(to: writeIntent.url, atomically: true, encoding: .utf8)
        return
      }

      guard !hasMached else {
        // The values of these changes are the same as the original ones, so we can just return
        // without save.
        return
      }

      if !replacementString.isEmpty {
        // We don't found mached lines, we need add new line.
        switch field {
        case .logLevel,
          .dnsServers,
          .exceptions,
          .httpListenAddress,
          .httpListenPort,
          .socksListenAddress,
          .socksListenPort,
          .excludeSimpleHostnames,
          .testURL,
          .testTimeout,
          .proxyTestURL,
          .dontAlertRejectErrors,
          .dontAllowRemoteAccess:
          if let range = lines.firstRange(match: /^ *\[General] *$/) {
            lines.insert("\(field.rawValue) = \(replacementString)", at: range.upperBound)
          } else {
            // Make General settings always on top of file.
            lines.insert("[General]", at: 0)
            lines.insert("\(field.rawValue) = \(replacementString)", at: 1)
          }
        case .skipCertificateVerification, .hostnames, .base64EncodedP12String, .passphrase:
          if let range = lines.firstRange(match: /^ *\[MitM] *$/) {
            lines.insert("\(field.rawValue) = \(replacementString)", at: range.upperBound)
          } else {
            // Make General settings always on top of file.
            lines.append("[MitM]")
            lines.append("\(field.rawValue) = \(replacementString)")
          }
        }
      }

      try lines
        .joined(separator: "\n")
        .write(to: writeIntent.url, atomically: true, encoding: .utf8)
    }
  }

  public func moveProfile(fromURL source: URL, to destination: URL) async throws {
    guard destination != source else {
      return
    }

    try await withCheckedThrowingContinuation { continuation in
      let sourceIntent = NSFileAccessIntent.writingIntent(with: source, options: .forMoving)
      let destinationIntent = NSFileAccessIntent.writingIntent(
        with: destination, options: .forReplacing)
      let coordinator = NSFileCoordinator(filePresenter: filePresenter)
      coordinator.coordinate(with: [sourceIntent, destinationIntent], queue: .init()) { error in
        do {
          if let error {
            throw error
          }
          try FileManager.default.moveItem(at: sourceIntent.url, to: destinationIntent.url)
          continuation.resume()
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }

    // Update profile resource if profile name changed.
    guard source.deletingLastPathComponent() == destination.deletingLastPathComponent() else {
      return
    }
    await Task { @MainActor in
      guard let original = profileResource.profiles.first(where: { $0.url == source }) else {
        return
      }

      var replacement = original
      replacement.url = destination
      var profiles = profileResource.profiles
      profiles.replace(CollectionOfOne(original), with: CollectionOfOne(replacement))
      profiles.sort(using: KeyPathComparator(\.name))
      profileResource.profiles = profiles
    }.value
  }

  /// Remove `Profile` item.
  ///
  /// - Parameter profile: The `Profile` item to be removed.
  public func delete(_ profile: Profile) async throws {
    try await withCheckedThrowingContinuation { continuation in
      let writeIntent = NSFileAccessIntent.writingIntent(with: profile.url, options: .forDeleting)
      let coordinator = NSFileCoordinator(filePresenter: filePresenter)
      coordinator.coordinate(with: [writeIntent], queue: .init()) { error in
        do {
          if let error {
            throw error
          }
          try FileManager.default.removeItem(at: writeIntent.url)
          continuation.resume()
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
    await Task { @MainActor in
      profileResource.profiles.removeAll(where: { $0.url == profile.url })
    }.value
  }
}
