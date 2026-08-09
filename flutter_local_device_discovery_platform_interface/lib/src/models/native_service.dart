import 'dart:typed_data';

import 'native_internet_address.dart';

/// A serializable service discovered by a native platform.
class NativeService {
  const NativeService({
    required this.id,
    required this.instanceName,
    required this.serviceType,
    required this.domain,
    this.hostname,
    this.addresses = const <NativeInternetAddress>[],
    this.port,
    required this.transport,
    this.rawTxtRecords = const <String, Uint8List>{},
    this.textTxtRecords = const <String, String>{},
    this.protocols = const <int>[],
    this.firstSeenAt,
    this.lastSeenAt,
    this.ttlSeconds,
    this.resolved = false,
    this.location,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String instanceName;
  final String serviceType;
  final String domain;
  final String? hostname;
  final List<NativeInternetAddress> addresses;
  final int? port;
  final int transport;
  final Map<String, Uint8List> rawTxtRecords;
  final Map<String, String> textTxtRecords;
  final List<int> protocols;
  final DateTime? firstSeenAt;
  final DateTime? lastSeenAt;
  final int? ttlSeconds;
  final bool resolved;
  final String? location;
  final Map<String, Object?> metadata;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'instanceName': instanceName,
      'serviceType': serviceType,
      'domain': domain,
      'hostname': hostname,
      'addresses': addresses.map((a) => a.toMap()).toList(),
      'port': port,
      'transport': transport,
      'rawTxtRecords': rawTxtRecords.map(
        (key, value) => MapEntry<String, Object?>(key, value),
      ),
      'textTxtRecords': textTxtRecords,
      'protocols': protocols,
      'firstSeenAt': firstSeenAt?.toIso8601String(),
      'lastSeenAt': lastSeenAt?.toIso8601String(),
      'ttlSeconds': ttlSeconds,
      'resolved': resolved,
      'location': location,
      'metadata': metadata,
    };
  }

  static Map<String, Object?> _stringMap(Object? value) {
    if (value is Map<Object?, Object?>) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return const {};
  }

  static NativeService fromMap(Map<Object?, Object?> map) {
    final rawAddresses = map['addresses'] as List<Object?>? ?? const [];
    final rawTxt = map['rawTxtRecords'] as Map<Object?, Object?>? ?? const {};
    final textTxt = map['textTxtRecords'] as Map<Object?, Object?>? ?? const {};

    final rawTxtRecords = <String, Uint8List>{};
    rawTxt.forEach((key, value) {
      if (key is String && value is Uint8List) {
        rawTxtRecords[key] = value;
      }
    });

    final textTxtRecords = <String, String>{};
    textTxt.forEach((key, value) {
      if (key is String && value is String) {
        textTxtRecords[key] = value;
      }
    });

    return NativeService(
      id: map['id']! as String,
      instanceName: map['instanceName']! as String,
      serviceType: map['serviceType']! as String,
      domain: map['domain']! as String,
      hostname: map['hostname'] as String?,
      addresses: rawAddresses
          .map(
            (a) => NativeInternetAddress.fromMap(a! as Map<Object?, Object?>),
          )
          .toList(),
      port: map['port'] as int?,
      transport: map['transport']! as int,
      rawTxtRecords: rawTxtRecords,
      textTxtRecords: textTxtRecords,
      protocols: (map['protocols'] as List<Object?>? ?? const [])
          .whereType<int>()
          .toList(),
      firstSeenAt: map['firstSeenAt'] != null
          ? DateTime.parse(map['firstSeenAt']! as String)
          : null,
      lastSeenAt: map['lastSeenAt'] != null
          ? DateTime.parse(map['lastSeenAt']! as String)
          : null,
      ttlSeconds: map['ttlSeconds'] as int?,
      resolved: map['resolved'] as bool? ?? false,
      location: map['location'] as String?,
      metadata: _stringMap(map['metadata']),
    );
  }
}
