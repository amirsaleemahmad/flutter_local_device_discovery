/// A device discovered via Bluetooth Low Energy scanning.
class BleDiscoveredDevice {
  const BleDiscoveredDevice({
    required this.id,
    this.name,
    this.rssi,
    this.serviceUuids = const <String>[],
    this.manufacturerData = const <int, List<int>>{},
    this.serviceData = const <String, List<int>>{},
    this.isConnectable,
    this.txPowerLevel,
    this.firstSeenAt,
    this.lastSeenAt,
    this.metadata = const <String, Object?>{},
  });

  /// Platform-specific device identifier.
  final String id;

  /// The advertised local name.
  final String? name;

  /// The RSSI signal strength in dBm.
  final int? rssi;

  /// Advertised service UUIDs.
  final List<String> serviceUuids;

  /// Manufacturer-specific data keyed by company ID.
  final Map<int, List<int>> manufacturerData;

  /// Service data keyed by service UUID.
  final Map<String, List<int>> serviceData;

  /// Whether the device is connectable.
  final bool? isConnectable;

  /// The transmitted power level in dBm.
  final int? txPowerLevel;

  /// When this device was first seen.
  final DateTime? firstSeenAt;

  /// When this device was last seen.
  final DateTime? lastSeenAt;

  /// Additional metadata.
  final Map<String, Object?> metadata;

  /// Creates a [BleDiscoveredDevice] from a JSON map.
  factory BleDiscoveredDevice.fromJson(Map<String, Object?> json) {
    return BleDiscoveredDevice(
      id: json['id'] as String,
      name: json['name'] as String?,
      rssi: json['rssi'] as int?,
      serviceUuids: (json['serviceUuids'] as List<dynamic>?)?.cast<String>() ?? const <String>[],
      manufacturerData: (json['manufacturerData'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), (v as List<dynamic>).cast<int>()),
          ) ??
          const <int, List<int>>{},
      serviceData: (json['serviceData'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as List<dynamic>).cast<int>()),
          ) ??
          const <String, List<int>>{},
      isConnectable: json['isConnectable'] as bool?,
      txPowerLevel: json['txPowerLevel'] as int?,
      firstSeenAt: json['firstSeenAt'] != null ? DateTime.tryParse(json['firstSeenAt'] as String) : null,
      lastSeenAt: json['lastSeenAt'] != null ? DateTime.tryParse(json['lastSeenAt'] as String) : null,
      metadata: (json['metadata'] as Map<String, dynamic>?)?.cast<String, Object?>() ?? const <String, Object?>{},
    );
  }

  /// Converts this [BleDiscoveredDevice] to a JSON map.
  Map<String, Object?> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (rssi != null) 'rssi': rssi,
      if (serviceUuids.isNotEmpty) 'serviceUuids': serviceUuids,
      if (manufacturerData.isNotEmpty) 'manufacturerData': manufacturerData.map((k, v) => MapEntry(k.toString(), v)),
      if (serviceData.isNotEmpty) 'serviceData': serviceData,
      if (isConnectable != null) 'isConnectable': isConnectable,
      if (txPowerLevel != null) 'txPowerLevel': txPowerLevel,
      if (firstSeenAt != null) 'firstSeenAt': firstSeenAt?.toIso8601String(),
      if (lastSeenAt != null) 'lastSeenAt': lastSeenAt?.toIso8601String(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }
}
