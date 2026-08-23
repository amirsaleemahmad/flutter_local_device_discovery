import 'dart:async';

import '../models/local_device.dart';
import '../models/local_service.dart';
import 'local_discovery_event.dart';
import 'local_discovery_request.dart';

/// The state of a discovery session.
enum LocalDiscoverySessionState {
  /// The session has been created but not started.
  created,

  /// The session is starting.
  starting,

  /// The session is running.
  running,

  /// The session is paused.
  paused,

  /// The session is stopping.
  stopping,

  /// The session has stopped.
  stopped,

  /// The session has failed.
  failed,
}

/// A discovery session.
abstract interface class LocalDiscoverySession {
  /// The unique identifier of this session.
  String get id;

  /// The request that created this session.
  LocalDiscoveryRequest get request;

  /// The current state of this session.
  LocalDiscoverySessionState get state;

  /// The stream of events emitted by this session.
  Stream<LocalDiscoveryEvent> get events;

  /// Returns a snapshot of the current discovery state.
  Future<LocalDiscoverySnapshot> snapshot();

  /// Pauses this session.
  Future<void> pause();

  /// Resumes this session.
  Future<void> resume();

  /// Stops this session and releases all resources.
  Future<void> stop();
}

/// A snapshot of the discovery state at a point in time.
class LocalDiscoverySnapshot {
  const LocalDiscoverySnapshot({
    required this.sessionId,
    this.devices = const <LocalDevice>[],
    this.services = const <LocalService>[],
    this.startedAt,
    this.completedAt,
    this.duration = Duration.zero,
  });

  /// The ID of the session that produced this snapshot.
  final String sessionId;

  /// The devices discovered in this snapshot.
  final List<LocalDevice> devices;

  /// The services discovered in this snapshot.
  final List<LocalService> services;

  /// When the discovery started.
  final DateTime? startedAt;

  /// When the discovery completed.
  final DateTime? completedAt;

  /// The duration of the discovery.
  final Duration duration;

  /// Converts this snapshot to a JSON-compatible map.
  Map<String, Object?> toJson() => {
        'sessionId': sessionId,
        'devices': devices.map((e) => e.toJson()).toList(),
        'services': services.map((e) => e.toJson()).toList(),
        if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        'duration': duration.inMilliseconds,
      };

  /// Creates a [LocalDiscoverySnapshot] from a JSON-compatible map.
  factory LocalDiscoverySnapshot.fromJson(Map<String, Object?> json) {
    return LocalDiscoverySnapshot(
      sessionId: json['sessionId'] as String,
      devices: (json['devices'] as List<dynamic>?)
              ?.map((e) => LocalDevice.fromJson(e as Map<String, Object?>))
              .toList() ??
          const <LocalDevice>[],
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => LocalService.fromJson(e as Map<String, Object?>))
              .toList() ??
          const <LocalService>[],
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'] as String) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      duration: Duration(milliseconds: json['duration'] as int? ?? 0),
    );
  }
}
