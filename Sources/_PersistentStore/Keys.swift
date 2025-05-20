//
// See LICENSE.txt for license information
//

// swift-format-ignore-file

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
  public static let maximumNumberOfProcesses = "Appearence - Maximum Number of Processes Displayed"

  #if EXTENDED_ALL
    public static let showNetworkConnectivityQualilty = "Appearence - Show Network Connectivity Quality"
    public static let showRemoteDashboardShortcuts = "Appearence - Show Remote Dashboard Shortcuts"
    public static let dockDisplayMode = "Appearence - Dock Display Mode"
    public static let isLocalNotificationsEnabled = "Notifications - Enable Local Notifications"
    public static let isCloudNotificationsEnabled = "Notifications - Enable Cloud Notifications"
    public static let shouldAutomaticallyDismissInessentialNotifications = "Notifications - Automatically Dismiss Inessential Notifications"
  #endif

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
