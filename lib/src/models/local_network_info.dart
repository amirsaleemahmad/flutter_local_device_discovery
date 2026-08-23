/// Information about the current network connection.
class LocalNetworkInfo {
  const LocalNetworkInfo({
    this.ssid,
    this.bssid,
    this.signalStrengthDbm,
    this.signalQuality,
    this.band,
    this.channelNumber,
    this.linkSpeedMbps,
    this.securityType,
    this.gatewayAddress,
    this.subnetMask,
    this.dnsServers = const <String>[],
    this.networkType = NetworkType.unknown,
    this.metadata = const <String, Object?>{},
  });

  /// The SSID of the current Wi-Fi network.
  final String? ssid;

  /// The BSSID (MAC address) of the access point.
  final String? bssid;

  /// Signal strength in dBm (e.g. -50).
  final int? signalStrengthDbm;

  /// Signal quality percentage (0-100).
  final int? signalQuality;

  /// The Wi-Fi frequency band.
  final WifiBand? band;

  /// The Wi-Fi channel number.
  final int? channelNumber;

  /// The link speed in Mbps.
  final int? linkSpeedMbps;

  /// The security type (e.g. 'WPA2', 'WPA3', 'Open').
  final String? securityType;

  /// The gateway IP address.
  final String? gatewayAddress;

  /// The subnet mask.
  final String? subnetMask;

  /// DNS server addresses.
  final List<String> dnsServers;

  /// The type of network connection.
  final NetworkType networkType;

  /// Additional platform-specific metadata.
  final Map<String, Object?> metadata;

  /// Creates a [LocalNetworkInfo] from a JSON map.
  factory LocalNetworkInfo.fromJson(Map<String, Object?> json) {
    return LocalNetworkInfo(
      ssid: json['ssid'] as String?,
      bssid: json['bssid'] as String?,
      signalStrengthDbm: json['signalStrengthDbm'] as int?,
      signalQuality: json['signalQuality'] as int?,
      band: json['band'] != null
          ? WifiBand.values.firstWhere(
              (e) => e.name == json['band'],
              orElse: () => WifiBand.band2_4GHz,
            )
          : null,
      channelNumber: json['channelNumber'] as int?,
      linkSpeedMbps: json['linkSpeedMbps'] as int?,
      securityType: json['securityType'] as String?,
      gatewayAddress: json['gatewayAddress'] as String?,
      subnetMask: json['subnetMask'] as String?,
      dnsServers: (json['dnsServers'] as List<dynamic>?)?.cast<String>() ?? const <String>[],
      networkType: NetworkType.values.firstWhere(
        (e) => e.name == json['networkType'],
        orElse: () => NetworkType.unknown,
      ),
      metadata: (json['metadata'] as Map<String, dynamic>?)?.cast<String, Object?>() ?? const <String, Object?>{},
    );
  }

  /// Converts this [LocalNetworkInfo] to a JSON map.
  Map<String, Object?> toJson() {
    return {
      if (ssid != null) 'ssid': ssid,
      if (bssid != null) 'bssid': bssid,
      if (signalStrengthDbm != null) 'signalStrengthDbm': signalStrengthDbm,
      if (signalQuality != null) 'signalQuality': signalQuality,
      if (band != null) 'band': band?.name,
      if (channelNumber != null) 'channelNumber': channelNumber,
      if (linkSpeedMbps != null) 'linkSpeedMbps': linkSpeedMbps,
      if (securityType != null) 'securityType': securityType,
      if (gatewayAddress != null) 'gatewayAddress': gatewayAddress,
      if (subnetMask != null) 'subnetMask': subnetMask,
      if (dnsServers.isNotEmpty) 'dnsServers': dnsServers,
      'networkType': networkType.name,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }
}

/// The Wi-Fi frequency band.
enum WifiBand {
  /// 2.4 GHz band.
  band2_4GHz,
  /// 5 GHz band.
  band5GHz,
  /// 6 GHz band (Wi-Fi 6E).
  band6GHz,
}

/// The type of network connection.
enum NetworkType {
  unknown,
  wifi,
  ethernet,
  cellular,
  vpn,
}
