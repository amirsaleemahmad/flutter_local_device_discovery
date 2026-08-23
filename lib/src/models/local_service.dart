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

  /// Converts this service to a JSON-compatible map.
  Map<String, Object?> toJson() => {
        'id': id,
        'instanceName': instanceName,
        'serviceType': serviceType,
        'domain': domain,
        if (hostname != null) 'hostname': hostname,
        'addresses': addresses.map((e) => e.toJson()).toList(),
        if (port != null) 'port': port,
        'transport': transport.name,
        'rawTxtRecords': rawTxtRecords.map((k, v) => MapEntry(k, v.toList())),
        'textTxtRecords': textTxtRecords,
        'discoveredBy': discoveredBy.map((e) => e.name).toList(),
        if (firstSeenAt != null) 'firstSeenAt': firstSeenAt!.toIso8601String(),
        if (lastSeenAt != null) 'lastSeenAt': lastSeenAt!.toIso8601String(),
        if (ttl != null) 'ttl': ttl!.inMilliseconds,
        'resolved': resolved,
        if (location != null) 'location': location!.toString(),
        'metadata': metadata,
      };

  /// Creates a [LocalService] from a JSON-compatible map.
  factory LocalService.fromJson(Map<String, Object?> json) {
    return LocalService(
      id: json['id'] as String,
      instanceName: json['instanceName'] as String,
      serviceType: json['serviceType'] as String,
      domain: json['domain'] as String,
      hostname: json['hostname'] as String?,
      addresses: (json['addresses'] as List<dynamic>?)
              ?.map((e) => InternetAddressValue.fromJson(e as Map<String, Object?>))
              .toList() ??
          const <InternetAddressValue>[],
      port: json['port'] as int?,
      transport: LocalTransportProtocol.values.byName(json['transport'] as String? ?? 'tcp'),
      rawTxtRecords: (json['rawTxtRecords'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, Uint8List.fromList((v as List<dynamic>).cast<int>())),
          ) ??
          const <String, Uint8List>{},
      textTxtRecords: (json['textTxtRecords'] as Map<String, dynamic>?)?.cast<String, String>() ?? const <String, String>{},
      discoveredBy: (json['discoveredBy'] as List<dynamic>?)
              ?.map((e) => LocalDiscoveryProtocol.values.byName(e as String))
              .toSet() ??
          const <LocalDiscoveryProtocol>{},
      firstSeenAt: json['firstSeenAt'] != null ? DateTime.parse(json['firstSeenAt'] as String) : null,
      lastSeenAt: json['lastSeenAt'] != null ? DateTime.parse(json['lastSeenAt'] as String) : null,
      ttl: json['ttl'] != null ? Duration(milliseconds: json['ttl'] as int) : null,
      resolved: json['resolved'] as bool? ?? false,
      location: json['location'] != null ? Uri.parse(json['location'] as String) : null,
      metadata: (json['metadata'] as Map<String, dynamic>?)?.cast<String, Object?>() ?? const <String, Object?>{},
    );
  }
}
