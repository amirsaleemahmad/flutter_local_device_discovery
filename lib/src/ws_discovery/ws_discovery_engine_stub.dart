import 'dart:async';

import '../models/metadata_security_policy.dart';
import '../models/ws_discovery_device.dart';

sealed class WsDiscoveryEngineEvent {
  const WsDiscoveryEngineEvent();
}

class WsDiscoveryDeviceDiscovered extends WsDiscoveryEngineEvent {
  const WsDiscoveryDeviceDiscovered(
    this.device, {
    this.isUpdate = false,
  });

  final WsDiscoveryDevice device;
  final bool isUpdate;
}

class WsDiscoveryDeviceExpired extends WsDiscoveryEngineEvent {
  const WsDiscoveryDeviceExpired(this.endpointReference);
  final String endpointReference;
}

class WsDiscoveryEngineWarning extends WsDiscoveryEngineEvent {
  const WsDiscoveryEngineWarning(this.message);
  final String message;
}

class WsDiscoveryDiscoveryEngine {
  WsDiscoveryDiscoveryEngine();

  Stream<WsDiscoveryEngineEvent> get events =>
      const Stream<WsDiscoveryEngineEvent>.empty();
  int get rawObservationCount => 0;
  int get wsDiscoveryFailureCount => 0;

  Future<void> start({
    required Set<String> wsDiscoveryTypes,
    required MetadataSecurityPolicy metadataSecurityPolicy,
    required bool includeLoopback,
    required bool includeLinkLocal,
    required bool includeVpnInterfaces,
    required bool includeCellularInterfaces,
    required bool includePeerToPeer,
    Duration searchInterval = const Duration(seconds: 30),
  }) {
    throw UnsupportedError('WS-Discovery is unavailable on this platform');
  }

  Future<void> pause() async {}
  Future<void> resume() async {}
  Future<void> stop() async {}
}
