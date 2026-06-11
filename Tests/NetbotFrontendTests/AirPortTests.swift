// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

import Testing

@testable import NetbotFrontend

struct AirPortTests {

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: zip(
      [0, 1, 2, 3, 4],
      [AirPort.ChannelWidth.unknown, .width20MHz, .width40MHz, .width80MHz, .width160MHz]))
  func channelWidthRawRepresentableConformance(rawValue: Int, channelWidth: AirPort.ChannelWidth)
    async
  {
    #expect(channelWidth == AirPort.ChannelWidth(rawValue: rawValue))
  }

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: zip(
      [AirPort.ChannelWidth.unknown, .width20MHz, .width40MHz, .width80MHz, .width160MHz],
      ["Unknown", "20MHz", "40MHz", "80MHz", "160MHz"]
    )
  )
  func channelWidthLocalizedName(channelWidth: AirPort.ChannelWidth, localizedName: String) async {
    #expect(channelWidth.localizedName == localizedName)
  }

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: zip(
      [0, 1, 2, 3],
      [AirPort.ChannelBand.unknown, .band2GHz, .band5GHz, .band6GHz]
    )
  )
  func channelBandRawRepresentableConformance(rawValue: Int, channelBand: AirPort.ChannelBand)
    async
  {
    #expect(channelBand == AirPort.ChannelBand(rawValue: rawValue))
  }

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: zip(
      [AirPort.ChannelBand.unknown, .band2GHz, .band5GHz, .band6GHz],
      ["Unknown", "2.4GHz", "5GHz", "6GHz"]
    )
  )
  func channelBandLocalizedName(channelBand: AirPort.ChannelBand, localizedName: String) async {
    #expect(channelBand.localizedName == localizedName)
  }

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: zip(
      [0, 1, 2, 3, 4, 5, 6],
      [AirPort.PHYMode.none, .mode11a, .mode11b, .mode11g, .mode11n, .mode11ac, .mode11ax]
    )
  )
  func physicalLayerModeRawRepresentableConformance(rawValue: Int, channelBand: AirPort.PHYMode)
    async
  {
    #expect(channelBand == AirPort.PHYMode(rawValue: rawValue))
  }

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: zip(
      [AirPort.PHYMode.none, .mode11a, .mode11b, .mode11g, .mode11n, .mode11ac, .mode11ax],
      ["none", "802.11a", "802.11b", "802.11g", "802.11n", "802.11ac", "802.11ax"]
    )
  )
  func physicalLayerModeLocalizedName(channelBand: AirPort.PHYMode, localizedName: String) async {
    #expect(channelBand.localizedName == localizedName)
  }

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: zip(
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 9_223_372_036_854_775_807],
      [
        AirPort.Security.none,
        .wep,
        .wpaPersonal,
        .wpaPersonalMixed,
        .wpa2Personal,
        .personal,
        .dynamicWEP,
        .wpaEnterprise,
        .wpaEnterpriseMixed,
        .wpa2Enterprise,
        .enterprise,
        .wpa3Personal,
        .wpa3Enterprise,
        .wpa3Transition,
        .owe,
        .oweTransition,
        .unknown,
      ]
    )
  )
  func securityRawRepresentableConformance(rawValue: Int, channelBand: AirPort.Security) async {
    #expect(channelBand == AirPort.Security(rawValue: rawValue))
  }

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: zip(
      [
        AirPort.Security.none,
        .wep,
        .wpaPersonal,
        .wpaPersonalMixed,
        .wpa2Personal,
        .personal,
        .dynamicWEP,
        .wpaEnterprise,
        .wpaEnterpriseMixed,
        .wpa2Enterprise,
        .enterprise,
        .wpa3Personal,
        .wpa3Enterprise,
        .wpa3Transition,
        .owe,
        .oweTransition,
        .unknown,
      ],
      [
        "none", "WEP", "WPA Personal", "WPA Personal Mixed", "WPA2 Personal", "Personal",
        "Dynamic WEP", "WPA Enterprise", "WPA Enterprise Mixed", "WPA2 Enterprise", "Enterprise",
        "WPA3 Personal", "WPA3 Enterprise", "WPA3 Transition", "OWE", "OWE Transition", "unknown",
      ]
    )
  )
  func securityLocalizedName(channelBand: AirPort.Security, localizedName: String) async {
    #expect(channelBand.localizedName == localizedName)
  }

  @available(SwiftStdlib 6.0, *)
  @MainActor @Test func defaultProperties() async {
    let airPort = AirPort()
    #expect(!airPort.isAvailable)
    #expect(airPort.interfaceName == "-")
    #expect(!airPort.powerOn)
    #expect(airPort.transmitRate == 0)
    #expect(airPort.mtu == 1500)
    #expect(airPort.mediaSubType == "N/A")
    #expect(airPort.ssid == "N/A")
    #expect(airPort.bssid == "N/A")
    #expect(airPort.countryCode == "N/A")
    #expect(airPort.rssi == 0)
    #expect(airPort.noise == 0)
    #expect(airPort.networkService == .init())
    #expect(airPort.publicIPs == [])
    #expect(airPort.hardwareAddress == "N/A")
    #expect(airPort.activePHYMode == .none)
    #expect(airPort.channelBand == .unknown)
    #expect(airPort.channelWidth == .unknown)
    #expect(airPort.channelNumber == 11)
    #expect(airPort.channel == "11 (Unknown, Unknown)")
    #expect(airPort.security == .none)
    #expect(airPort.transmitPower == 0)
  }
}
