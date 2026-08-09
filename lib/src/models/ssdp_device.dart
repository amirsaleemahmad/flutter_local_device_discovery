/// A device discovered via SSDP (Simple Service Discovery Protocol).
class SsdpDevice {
  const SsdpDevice({
    required this.location,
    required this.usn,
    required this.searchTarget,
    this.server,
    this.cacheControlMaxAge,
    this.bootId,
    this.configId,
    this.friendlyName,
    this.manufacturer,
    this.modelName,
    this.udn,
    this.deviceType,
    this.sourceAddress,
    this.headers = const <String, String>{},
    this.lastSeenAt,
  });

  /// The LOCATION header URL for the UPnP description document.
  final String location;

  /// The Unique Service Name (USN) header.
  final String usn;

  /// The Search Target (ST) header.
  final String searchTarget;

  /// The SERVER header describing the device's server software.
  final String? server;

  /// The cache-control max-age in seconds.
  final int? cacheControlMaxAge;

  /// The boot identifier.
  final String? bootId;

  /// The configuration identifier.
  final String? configId;

  /// The friendly name from UPnP description (if parsed).
  final String? friendlyName;

  /// The manufacturer from UPnP description (if parsed).
  final String? manufacturer;

  /// The model name from UPnP description (if parsed).
  final String? modelName;

  /// The Unique Device Name (UDN) from UPnP description.
  final String? udn;

  /// The device type from UPnP description.
  final String? deviceType;

  /// The address from which the SSDP datagram was received.
  final String? sourceAddress;

  /// Normalized, lower-case SSDP response headers.
  final Map<String, String> headers;

  /// When this advertisement was most recently observed.
  final DateTime? lastSeenAt;

  /// Returns a copy with optional UPnP enrichment.
  SsdpDevice copyWith({
    String? location,
    String? usn,
    String? searchTarget,
    String? server,
    int? cacheControlMaxAge,
    String? bootId,
    String? configId,
    String? friendlyName,
    String? manufacturer,
    String? modelName,
    String? udn,
    String? deviceType,
    String? sourceAddress,
    Map<String, String>? headers,
    DateTime? lastSeenAt,
  }) {
    return SsdpDevice(
      location: location ?? this.location,
      usn: usn ?? this.usn,
      searchTarget: searchTarget ?? this.searchTarget,
      server: server ?? this.server,
      cacheControlMaxAge: cacheControlMaxAge ?? this.cacheControlMaxAge,
      bootId: bootId ?? this.bootId,
      configId: configId ?? this.configId,
      friendlyName: friendlyName ?? this.friendlyName,
      manufacturer: manufacturer ?? this.manufacturer,
      modelName: modelName ?? this.modelName,
      udn: udn ?? this.udn,
      deviceType: deviceType ?? this.deviceType,
      sourceAddress: sourceAddress ?? this.sourceAddress,
      headers: headers ?? this.headers,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SsdpDevice && other.usn == usn && other.location == location;

  @override
  int get hashCode => Object.hash(usn, location);

  @override
  String toString() =>
      'SsdpDevice(location: $location, usn: $usn, st: $searchTarget)';
}
