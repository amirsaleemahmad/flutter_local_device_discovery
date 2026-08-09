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
}
