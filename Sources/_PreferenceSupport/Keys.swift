// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

// swift-format-ignore-file

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
@available(SwiftStdlib 5.5, *)
#else
@available(SwiftStdlib 6.0, *)
#endif
extension Prefs.Name {

  public static let logLevel = "Logging - Logger Level"

  public static let maxminddbDownloadURL =  "MaxMindDB - GeoLite2-Country Download URL"
  public static let maxminddbKeepUpToDate = "MaxMindDB - Keep MaxMindDB up to Date"
  public static let maxminddbLastUpdatedDate = "MaxMindDB - MaxMindDB Last Updated Date"

  public static let profileURL = "Profile - User Selected Profile URL"
  public static let profilesDirectory = "Profile - User Selected Profiles Directory"
  public static let profileAutoreload = "Profile - Automatically Reload if the Profile Was Modified"
  public static let profileLastContentModificationDate = "Profile - Last Content Modification Date"

  public static let forwardingRuleResourcesLastUpdatedDate = "External Resources - Forwarding Rules External Resources Last Updated Date"

  public static let menuBarExtraTitleLabelStyle = "Appearence - MenuBarExtra Title Label Style"
  public static let showMainWindowAfterLaunching = "Appearence - Show Main Window After Launching"
  public static let shouldGrayOutStatusBarItem = "Appearence - Should Gray Out Status Bar Item"
  public static let shouldCollapsePolicyGroupIfThereAreMoreThanFiveItems = "Appearence - Should Collapse Policy Group if There Are More Than Five Items"
  public static let processFetchLimit = "Appearence - Maximum Number of Processes Displayed"

  public static let showNetworkConnectivityQualilty = "Appearence - Show Network Connectivity Quality"
  public static let showRemoteDashboardShortcuts = "Appearence - Show Remote Dashboard Shortcuts"
  public static let dockDisplayMode = "Appearence - Dock Display Mode"
  public static let isLocalNotificationsEnabled = "Notifications - Enable Local Notifications"
  public static let isCloudNotificationsEnabled = "Notifications - Enable Cloud Notifications"
  public static let shouldAutomaticallyDismissInessentialNotifications = "Notifications - Automatically Dismiss Inessential Notifications"

  public static let selectionRecordForGroups = "Policy Group - Preferred Policy Selection Record for Policy Groups"

  public static let proxyMode = "Proxies - Proxy Mode"

  public static let enabledHTTPCapabilities = "HTTP - Enabled HTTP Capabilities"
  public static let outboundMode = "Outbound Mode"

  public static let hideRequestsThatBelongToApple = "Replica - Hide Requests That Blong to Apple"
  public static let hideRequestsThatBelongToCrashReporters = "Replica - Hide Requests That Blong to Crash Reporters"
  public static let hideUDPConversations = "Replica - Hide UDP Conversations"
  public static let combineSystemProcesses = "Replica - Combine Systen Processes"

  public static let dns = "DNS - Cleartext DNS Server Type"
  public static let shouldReadLocalDNSRecords = "DNS - Read Local DNS Records from /etc/hosts"
  public static let shouldEnableLocalDNSMapping = "DNS - Enable Local DNS Mapping"
}
