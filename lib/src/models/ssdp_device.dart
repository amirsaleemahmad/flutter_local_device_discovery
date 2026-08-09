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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SsdpDevice && other.usn == usn && other.location == location;

  @override
  int get hashCode => Object.hash(usn, location);

  @override
  String toString() => 'SsdpDevice(location: $location, usn: $usn, st: $searchTarget)';
}