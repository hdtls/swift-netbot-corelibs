//
// See LICENSE.txt for license information
//

#if canImport(Darwin)
  import Anlzr
  import AnlzrReports
  import Atomics
  import Foundation
  import HTTPTypes
  import Logging
  import NIOTransportServices
  import Testing
  import _PreferenceSupport

  @testable import _NEAnalytics

  @Suite struct AutoreloadTests {

    final class Delegate: AutoreloadDelegate {
      let autoReloadEnabledHTTPCapabilitiesCalls = ManagedAtomic(0)
      let autoReloadGeoLite2Calls = ManagedAtomic(0)
      let autoReloadOutboundModeCalls = ManagedAtomic(0)
      let autoReloadProfileCalls = ManagedAtomic(0)

      func autoReloadEnabledHTTPCapabilities(_ capabilities: Anlzr.CapabilityFlags) {
        autoReloadEnabledHTTPCapabilitiesCalls.wrappingIncrement(ordering: .relaxed)
      }

      func autoReloadGeoLite2(filePath: String) {
        autoReloadGeoLite2Calls.wrappingIncrement(ordering: .relaxed)
      }

      func autoReloadOutboundMode(_ mode: Anlzr.OutboundMode) {
        autoReloadOutboundModeCalls.wrappingIncrement(ordering: .relaxed)
      }

      func autoReloadProfile(url: URL, mode: ProxyMode) {
        autoReloadProfileCalls.wrappingIncrement(ordering: .relaxed)
      }
    }

    func autoreload(
      _ testCase: String, execute: (AutoreloadSubscription, Delegate) async throws -> Void
    ) async rethrows {
      let domain = "com.tenbits.netbot.defaults.\(testCase)"
      guard let defaults = UserDefaults(suiteName: domain) else {
        #expect(Bool(false), "Failed to create UserDefaults")
        return
      }

      defaults.removePersistentDomain(forName: domain)
      // Avoid data downloading during tests.
      defaults.set(Date.now, forKey: Prefs.Name.maxminddbLastUpdatedDate)
      defaults.set(Date.now, forKey: Prefs.Name.forwardingRuleResourcesLastUpdatedDate)
      defaults.set(true, forKey: Prefs.Name.profileAutoreload)

      let delegate = Delegate()
      let autoreload = AutoreloadSubscription(
        group: NIOTSEventLoopGroup(numberOfThreads: 1),
        store: defaults
      )
      autoreload.delegate = delegate

      try await execute(autoreload, delegate)
    }

    @Test func beforeRun() async throws {
      await autoreload(#function) { _, delegate in
        #expect(delegate.autoReloadEnabledHTTPCapabilitiesCalls.load(ordering: .relaxed) == 0)
        #expect(delegate.autoReloadGeoLite2Calls.load(ordering: .relaxed) == 0)
        #expect(delegate.autoReloadOutboundModeCalls.load(ordering: .relaxed) == 0)
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 0)
      }
    }

    @Test func afterRun() async throws {
      try await autoreload(#function) { autoreload, delegate in
        try await autoreload.run()
        #expect(delegate.autoReloadEnabledHTTPCapabilitiesCalls.load(ordering: .relaxed) == 1)
        #expect(delegate.autoReloadGeoLite2Calls.load(ordering: .relaxed) == 1)
        #expect(delegate.autoReloadOutboundModeCalls.load(ordering: .relaxed) == 1)
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)
      }
    }

    @Test func afterShutdown() async throws {
      try await autoreload(#function) { autoreload, delegate in
        try await autoreload.run()
        #expect(delegate.autoReloadEnabledHTTPCapabilitiesCalls.load(ordering: .relaxed) == 1)
        #expect(delegate.autoReloadGeoLite2Calls.load(ordering: .relaxed) == 1)
        #expect(delegate.autoReloadOutboundModeCalls.load(ordering: .relaxed) == 1)
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)

        await autoreload.shutdownGracefully()

        autoreload.enabledHTTPCapabilities = .httpsDecryption
        #expect(delegate.autoReloadEnabledHTTPCapabilitiesCalls.load(ordering: .relaxed) == 1)

        autoreload.outboundMode = .ruleBased
        #expect(delegate.autoReloadOutboundModeCalls.load(ordering: .relaxed) == 1)

        autoreload.maxminddbLastUpdatedDate = .now
        #expect(delegate.autoReloadGeoLite2Calls.load(ordering: .relaxed) == 1)

        autoreload.profileURL = .cachesDirectory
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)

        autoreload.selectionRecords = "{ \"A\": {} }"
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)

        autoreload.profileLastContentModificationDate = .now
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)

        autoreload.forwardingRuleResourcesLastUpdatedDate = .now
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)

        autoreload.proxyMode = .enhanced
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)
      }
    }

    @Test func reRunAfterShutdown() async throws {
      try await autoreload(#function) { autoreload, delegate in
        try await autoreload.run()
        #expect(delegate.autoReloadEnabledHTTPCapabilitiesCalls.load(ordering: .relaxed) == 1)
        #expect(delegate.autoReloadGeoLite2Calls.load(ordering: .relaxed) == 1)
        #expect(delegate.autoReloadOutboundModeCalls.load(ordering: .relaxed) == 1)
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)

        await autoreload.shutdownGracefully()

        try await autoreload.run()
        #expect(delegate.autoReloadEnabledHTTPCapabilitiesCalls.load(ordering: .relaxed) == 2)
        #expect(delegate.autoReloadGeoLite2Calls.load(ordering: .relaxed) == 2)
        #expect(delegate.autoReloadOutboundModeCalls.load(ordering: .relaxed) == 2)
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 2)
      }
    }

    @Test func reloadEnabledHTTPCapabilities() async throws {
      try await autoreload(#function) { autoreload, delegate in
        try await autoreload.run()
        #expect(delegate.autoReloadEnabledHTTPCapabilitiesCalls.load(ordering: .relaxed) == 1)
        autoreload.enabledHTTPCapabilities = .httpCapture
        #expect(delegate.autoReloadEnabledHTTPCapabilitiesCalls.load(ordering: .relaxed) == 2)
      }
    }

    @Test func removeDuplicatedReloadEnabledHTTPCapabilities() async throws {
      try await autoreload(#function) { autoreload, delegate in
        try await autoreload.run()
        #expect(delegate.autoReloadEnabledHTTPCapabilitiesCalls.load(ordering: .relaxed) == 1)
        autoreload.enabledHTTPCapabilities = .httpCapture
        #expect(delegate.autoReloadEnabledHTTPCapabilitiesCalls.load(ordering: .relaxed) == 2)
        autoreload.enabledHTTPCapabilities = .httpCapture
        #expect(delegate.autoReloadEnabledHTTPCapabilitiesCalls.load(ordering: .relaxed) == 2)
      }
    }

    @Test func reloadGeoLite2AfterLastUpdateDateChanaged() async throws {
      try await autoreload(#function) { autoreload, delegate in
        try await autoreload.run()
        #expect(delegate.autoReloadGeoLite2Calls.load(ordering: .relaxed) == 1)
        autoreload.maxminddbLastUpdatedDate = .now
        #expect(delegate.autoReloadGeoLite2Calls.load(ordering: .relaxed) == 2)
      }
    }

    @Test func removeDuplicatedReloadGeoLite2() async throws {
      try await autoreload(#function) { autoreload, delegate in
        try await autoreload.run()
        #expect(delegate.autoReloadGeoLite2Calls.load(ordering: .relaxed) == 1)
        autoreload.maxminddbLastUpdatedDate = .distantFuture
        #expect(delegate.autoReloadGeoLite2Calls.load(ordering: .relaxed) == 2)
        autoreload.maxminddbLastUpdatedDate = .distantFuture
        #expect(delegate.autoReloadGeoLite2Calls.load(ordering: .relaxed) == 2)
      }
    }

    @Test func skipReloadGeoLite2AfterLastUpdateDateChangedToDistantPast() async throws {
      try await autoreload(#function) { autoreload, delegate in
        try await autoreload.run()
        #expect(delegate.autoReloadGeoLite2Calls.load(ordering: .relaxed) == 1)
        autoreload.maxminddbLastUpdatedDate = .distantPast
        #expect(delegate.autoReloadGeoLite2Calls.load(ordering: .relaxed) == 1)
      }
    }

    @Test func reloadOutboundMode() async throws {
      try await autoreload(#function) { autoreload, delegate in
        try await autoreload.run()
        #expect(delegate.autoReloadOutboundModeCalls.load(ordering: .relaxed) == 1)
        autoreload.outboundMode = .ruleBased
        #expect(delegate.autoReloadOutboundModeCalls.load(ordering: .relaxed) == 2)
      }
    }

    @Test func removeDuplicatedReloadOutboundMode() async throws {
      try await autoreload(#function) { autoreload, delegate in
        try await autoreload.run()
        #expect(delegate.autoReloadOutboundModeCalls.load(ordering: .relaxed) == 1)
        autoreload.outboundMode = .ruleBased
        #expect(delegate.autoReloadOutboundModeCalls.load(ordering: .relaxed) == 2)
        autoreload.outboundMode = .ruleBased
        #expect(delegate.autoReloadOutboundModeCalls.load(ordering: .relaxed) == 2)
      }
    }

    @Test func reloadProfileAfterProfileURLChanged() async throws {
      try await autoreload(#function) { autoreload, delegate in
        try await autoreload.run()
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)
        autoreload.profileURL = .cachesDirectory
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 2)
      }
    }

    @Test func reloadProfileAfterSelectionChanged() async throws {
      try await autoreload(#function) { autoreload, delegate in
        try await autoreload.run()
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)
        autoreload.selectionRecords = "{ \"A\": {} }"
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 2)
      }
    }

    @Test func reloadProfileAfterProxyModeChanged() async throws {
      try await autoreload(#function) { autoreload, delegate in
        try await autoreload.run()
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)
        autoreload.proxyMode = .systemProxy
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 2)
      }
    }

    @Test func reloadProfileAfterProfileLastContentModificationDateChanged() async throws {
      try await autoreload(#function) { autoreload, delegate in
        try await autoreload.run()
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)
        autoreload.profileLastContentModificationDate = .now.addingTimeInterval(-10)
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 2)
      }
    }

    @Test func reloadProfileAfterForwardingRuleResourcesLastUpdateDateChanged() async throws {
      try await autoreload(#function) { autoreload, delegate in
        try await autoreload.run()
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)
        autoreload.forwardingRuleResourcesLastUpdatedDate = .now.addingTimeInterval(-10)
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 2)
      }
    }

    @Test func reloadProfileAfterAutoreloadEnabled() async throws {
      try await autoreload(#function) { autoreload, delegate in
        try await autoreload.run()
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)
        autoreload.profileAutoreload = false
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)
        autoreload.profileAutoreload = true
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 2)
        autoreload.profileAutoreload = false
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 2)
      }
    }

    @Test func skipReloadProfileIfLastContentModificationDateChangedToDistantPast() async throws {
      try await autoreload(#function) { autoreload, delegate in
        try await autoreload.run()
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)
        autoreload.profileLastContentModificationDate = .distantPast
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)
      }
    }

    @Test func skipReloadProfileIfForwardingRuleResourcesLastUpdateDateChangedToDistantPast()
      async throws
    {
      try await autoreload(#function) { autoreload, delegate in
        try await autoreload.run()
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)
        autoreload.forwardingRuleResourcesLastUpdatedDate = .distantPast
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)
      }
    }

    @Test func skipReloadProfileIfAutoreloadIsDisabled() async throws {
      try await autoreload(#function) { autoreload, delegate in
        try await autoreload.run()
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)
        autoreload.profileAutoreload = false
        autoreload.profileLastContentModificationDate = .now
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)
        autoreload.forwardingRuleResourcesLastUpdatedDate = .now
        #expect(delegate.autoReloadProfileCalls.load(ordering: .relaxed) == 1)
      }
    }
  }
#endif
