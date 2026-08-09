import 'native_device.dart';
import 'native_service.dart';

/// A serializable discovery event sent from native platforms.
class NativeDiscoveryEvent {
  const NativeDiscoveryEvent({
    required this.type,
    this.device,
    this.service,
    this.sessionId,
    this.errorCode,
    this.errorMessage,
    this.protocol,
    this.timestamp,
    this.metadata = const <String, Object?>{},
  });

  final int type;
  final NativeDevice? device;
  final NativeService? service;
  final String? sessionId;
  final String? errorCode;
  final String? errorMessage;
  final int? protocol;
  final DateTime? timestamp;
  final Map<String, Object?> metadata;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'type': type,
      'device': device?.toMap(),
      'service': service?.toMap(),
      'sessionId': sessionId,
      'errorCode': errorCode,
      'errorMessage': errorMessage,
      'protocol': protocol,
      'timestamp': timestamp?.toIso8601String(),
      'metadata': metadata,
    };
  }

  static Map<String, Object?> _stringMap(Object? value) {
    if (value is Map<Object?, Object?>) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return const {};
  }

  static NativeDiscoveryEvent fromMap(Map<Object?, Object?> map) {
    final rawDevice = map['device'] as Map<Object?, Object?>?;
    final rawService = map['service'] as Map<Object?, Object?>?;

    return NativeDiscoveryEvent(
      type: map['type']! as int,
      device: rawDevice != null ? NativeDevice.fromMap(rawDevice) : null,
      service: rawService != null ? NativeService.fromMap(rawService) : null,
      sessionId: map['sessionId'] as String?,
      errorCode: map['errorCode'] as String?,
      errorMessage: map['errorMessage'] as String?,
      protocol: map['protocol'] as int?,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp']! as String)
          : null,
      metadata: _stringMap(map['metadata']),
    );
  }
}
