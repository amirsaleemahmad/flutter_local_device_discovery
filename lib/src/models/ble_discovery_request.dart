/// Configuration for BLE device discovery.
class BleDiscoveryRequest {
  const BleDiscoveryRequest({
    this.serviceUuids = const <String>{},
    this.scanDuration = const Duration(seconds: 10),
    this.reportDuplicates = false,
    this.metadata = const <String, Object?>{},
  });

  /// BLE service UUIDs to filter for (e.g. 'FFF6' for Matter).
  final Set<String> serviceUuids;

  /// How long to scan.
  final Duration scanDuration;

  /// Whether to report duplicate advertisements.
  final bool reportDuplicates;

  /// Additional metadata.
  final Map<String, Object?> metadata;

  /// Creates a [BleDiscoveryRequest] from a JSON map.
  factory BleDiscoveryRequest.fromJson(Map<String, Object?> json) {
    return BleDiscoveryRequest(
      serviceUuids: (json['serviceUuids'] as List<dynamic>?)?.cast<String>().toSet() ?? const <String>{},
      scanDuration: json['scanDuration'] != null
          ? Duration(milliseconds: json['scanDuration'] as int)
          : const Duration(seconds: 10),
      reportDuplicates: json['reportDuplicates'] as bool? ?? false,
      metadata: (json['metadata'] as Map<String, dynamic>?)?.cast<String, Object?>() ?? const <String, Object?>{},
    );
  }

  /// Converts this [BleDiscoveryRequest] to a JSON map.
  Map<String, Object?> toJson() {
    return {
      'serviceUuids': serviceUuids.toList(),
      'scanDuration': scanDuration.inMilliseconds,
      'reportDuplicates': reportDuplicates,
      'metadata': metadata,
    };
  }
}
