/// Serializable discovery diagnostics from a native platform.
class NativeDiscoveryDiagnostics {
  const NativeDiscoveryDiagnostics({
    this.pluginVersion,
    this.platformVersion,
    this.supportedProtocols = const <int>[],
    this.activeSessions = 0,
    this.networkInterfaces = const <String>[],
    this.multicastAvailable = false,
    this.localNetworkReady = false,
    this.rawObservationCount = 0,
    this.deduplicatedDeviceCount = 0,
    this.resolutionSuccessCount = 0,
    this.resolutionFailureCount = 0,
    this.metadataFetchCount = 0,
    this.droppedEventCount = 0,
    this.lastNetworkChangeAt,
    this.warnings = const <String>[],
    this.platformDetails = const <String, Object?>{},
  });

  final String? pluginVersion;
  final String? platformVersion;
  final List<int> supportedProtocols;
  final int activeSessions;
  final List<String> networkInterfaces;
  final bool multicastAvailable;
  final bool localNetworkReady;
  final int rawObservationCount;
  final int deduplicatedDeviceCount;
  final int resolutionSuccessCount;
  final int resolutionFailureCount;
  final int metadataFetchCount;
  final int droppedEventCount;
  final DateTime? lastNetworkChangeAt;
  final List<String> warnings;
  final Map<String, Object?> platformDetails;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'pluginVersion': pluginVersion,
      'platformVersion': platformVersion,
      'supportedProtocols': supportedProtocols,
      'activeSessions': activeSessions,
      'networkInterfaces': networkInterfaces,
      'multicastAvailable': multicastAvailable,
      'localNetworkReady': localNetworkReady,
      'rawObservationCount': rawObservationCount,
      'deduplicatedDeviceCount': deduplicatedDeviceCount,
      'resolutionSuccessCount': resolutionSuccessCount,
      'resolutionFailureCount': resolutionFailureCount,
      'metadataFetchCount': metadataFetchCount,
      'droppedEventCount': droppedEventCount,
      'lastNetworkChangeAt': lastNetworkChangeAt?.toIso8601String(),
      'warnings': warnings,
      'platformDetails': platformDetails,
    };
  }

  static Map<String, Object?> _stringMap(Object? value) {
    if (value is Map<Object?, Object?>) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return const {};
  }

  static NativeDiscoveryDiagnostics fromMap(Map<Object?, Object?> map) {
    return NativeDiscoveryDiagnostics(
      pluginVersion: map['pluginVersion'] as String?,
      platformVersion: map['platformVersion'] as String?,
      supportedProtocols:
          (map['supportedProtocols'] as List<Object?>? ?? const [])
              .whereType<int>()
              .toList(),
      activeSessions: map['activeSessions'] as int? ?? 0,
      networkInterfaces:
          (map['networkInterfaces'] as List<Object?>? ?? const [])
              .whereType<String>()
              .toList(),
      multicastAvailable: map['multicastAvailable'] as bool? ?? false,
      localNetworkReady: map['localNetworkReady'] as bool? ?? false,
      rawObservationCount: map['rawObservationCount'] as int? ?? 0,
      deduplicatedDeviceCount: map['deduplicatedDeviceCount'] as int? ?? 0,
      resolutionSuccessCount: map['resolutionSuccessCount'] as int? ?? 0,
      resolutionFailureCount: map['resolutionFailureCount'] as int? ?? 0,
      metadataFetchCount: map['metadataFetchCount'] as int? ?? 0,
      droppedEventCount: map['droppedEventCount'] as int? ?? 0,
      lastNetworkChangeAt: map['lastNetworkChangeAt'] != null
          ? DateTime.parse(map['lastNetworkChangeAt']! as String)
          : null,
      warnings: (map['warnings'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(),
      platformDetails: _stringMap(map['platformDetails']),
    );
  }
}
