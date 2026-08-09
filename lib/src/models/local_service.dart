import 'dart:typed_data';

import 'internet_address_value.dart';
import '../discovery/local_discovery_protocol.dart';

/// The transport protocol used by a service.
enum LocalTransportProtocol {
  /// TCP.
  tcp,

  /// UDP.
  udp,
}

/// A service discovered on the local network.
class LocalService {
  const LocalService({
    required this.id,
    required this.instanceName,
    required this.serviceType,
    required this.domain,
    this.hostname,
    this.addresses = const <InternetAddressValue>[],
    this.port,
    this.transport = LocalTransportProtocol.tcp,
    this.rawTxtRecords = const <String, Uint8List>{},
    this.textTxtRecords = const <String, String>{},
    this.discoveredBy = const <LocalDiscoveryProtocol>{},
    this.firstSeenAt,
    this.lastSeenAt,
    this.ttl,
    this.resolved = false,
    this.location,
    this.metadata = const <String, Object?>{},
  });

  /// A stable identifier for this service.
  final String id;

  /// The instance name of the service (e.g., `My Printer`).
  final String instanceName;

  /// The service type (e.g., `_ipp._tcp`).
  final String serviceType;

  /// The domain in which the service was discovered (e.g., `local.`).
  final String domain;

  /// The hostname of the device providing this service.
  final String? hostname;

  /// The resolved addresses of this service.
  final List<InternetAddressValue> addresses;

  /// The port on which the service is available.
  final int? port;

  /// The transport protocol used by this service.
  final LocalTransportProtocol transport;

  /// Raw TXT record values, preserving original bytes.
  final Map<String, Uint8List> rawTxtRecords;

  /// Decoded text TXT record values.
  final Map<String, String> textTxtRecords;

  /// The protocols that discovered this service.
  final Set<LocalDiscoveryProtocol> discoveredBy;

  /// When this service was first seen.
  final DateTime? firstSeenAt;

  /// When this service was last seen.
  final DateTime? lastSeenAt;

  /// The advertised TTL of this service.
  final Duration? ttl;

  /// Whether this service has been resolved.
  final bool resolved;

  /// The location URL (e.g., UPnP description URL).
  final Uri? location;

  /// Additional metadata about this service.
  final Map<String, Object?> metadata;

  /// Returns the decoded value of a TXT record key, or `null` if not present.
  String? txt(String key) => textTxtRecords[key];

  /// Returns the raw bytes of a TXT record key, or `null` if not present.
  Uint8List? rawTxt(String key) => rawTxtRecords[key];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocalService &&
        other.id == id &&
        other.instanceName == instanceName &&
        other.serviceType == serviceType &&
        other.domain == domain &&
        other.hostname == hostname &&
        other.port == port &&
        other.transport == transport &&
        other.resolved == resolved;
  }

  @override
  int get hashCode => Object.hash(
        id,
        instanceName,
        serviceType,
        domain,
        hostname,
        port,
        transport,
        resolved,
      );

  @override
  String toString() {
    return 'LocalService('
        'instanceName: $instanceName, '
        'serviceType: $serviceType, '
        'port: $port, '
        'resolved: $resolved)';
  }
}
