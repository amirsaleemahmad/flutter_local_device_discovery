import 'native_internet_address.dart';
import 'native_service.dart';

/// A serializable device observed by a native platform.
class NativeDevice {
  const NativeDevice({
    required this.id,
    required this.displayName,
    this.hostname,
    this.addresses = const <NativeInternetAddress>[],
    this.interfaces = const <String>[],
    this.services = const <NativeService>[],
    this.type = 0,
    this.capabilities = const <int>[],
    this.macAddress,
    this.serviceInstance,
    this.uniqueDeviceName,
    this.upnpUdn,
    this.wsEndpointReference,
    this.serialNumber,
    this.model,
    this.manufacturer,
    this.identifiers = const <String, String>{},
    this.protocols = const <int>[],
    this.firstSeenAt,
    this.lastSeenAt,
    this.ttlSeconds,
    this.confidence = 0.0,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String displayName;
  final String? hostname;
  final List<NativeInternetAddress> addresses;
  final List<String> interfaces;
  final List<NativeService> services;
  final int type;
  final List<int> capabilities;
  final String? macAddress;
  final String? serviceInstance;
  final String? uniqueDeviceName;
  final String? upnpUdn;
  final String? wsEndpointReference;
  final String? serialNumber;
  final String? model;
  final String? manufacturer;
  final Map<String, String> identifiers;
  final List<int> protocols;
  final DateTime? firstSeenAt;
  final DateTime? lastSeenAt;
  final int? ttlSeconds;
  final double confidence;
  final Map<String, Object?> metadata;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'displayName': displayName,
      'hostname': hostname,
      'addresses': addresses.map((a) => a.toMap()).toList(),
      'interfaces': interfaces,
      'services': services.map((s) => s.toMap()).toList(),
      'type': type,
      'capabilities': capabilities,
      'macAddress': macAddress,
      'serviceInstance': serviceInstance,
      'uniqueDeviceName': uniqueDeviceName,
      'upnpUdn': upnpUdn,
      'wsEndpointReference': wsEndpointReference,
      'serialNumber': serialNumber,
      'model': model,
      'manufacturer': manufacturer,
      'identifiers': identifiers,
      'protocols': protocols,
      'firstSeenAt': firstSeenAt?.toIso8601String(),
      'lastSeenAt': lastSeenAt?.toIso8601String(),
      'ttlSeconds': ttlSeconds,
      'confidence': confidence,
      'metadata': metadata,
    };
  }

  static Map<String, Object?> _stringMap(Object? value) {
    if (value is Map<Object?, Object?>) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return const {};
  }

  static Map<String, String> _stringStringMap(Object? value) {
    if (value is Map<Object?, Object?>) {
      return value.map((key, val) => MapEntry(key.toString(), val.toString()));
    }
    return const {};
  }

  static NativeDevice fromMap(Map<Object?, Object?> map) {
    final rawAddresses = map['addresses'] as List<Object?>? ?? const [];
    final rawServices = map['services'] as List<Object?>? ?? const [];

    return NativeDevice(
      id: map['id']! as String,
      displayName: map['displayName']! as String,
      hostname: map['hostname'] as String?,
      addresses: rawAddresses
          .map(
            (a) => NativeInternetAddress.fromMap(a! as Map<Object?, Object?>),
          )
          .toList(),
      interfaces: (map['interfaces'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(),
      services: rawServices
          .map((s) => NativeService.fromMap(s! as Map<Object?, Object?>))
          .toList(),
      type: map['type'] as int? ?? 0,
      capabilities: (map['capabilities'] as List<Object?>? ?? const [])
          .whereType<int>()
          .toList(),
      macAddress: map['macAddress'] as String?,
      serviceInstance: map['serviceInstance'] as String?,
      uniqueDeviceName: map['uniqueDeviceName'] as String?,
      upnpUdn: map['upnpUdn'] as String?,
      wsEndpointReference: map['wsEndpointReference'] as String?,
      serialNumber: map['serialNumber'] as String?,
      model: map['model'] as String?,
      manufacturer: map['manufacturer'] as String?,
      identifiers: _stringStringMap(map['identifiers']),
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
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      metadata: _stringMap(map['metadata']),
    );
  }
}
