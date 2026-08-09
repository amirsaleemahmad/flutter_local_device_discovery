import 'dart:async';

import '../models/metadata_security_policy.dart';
import '../models/ssdp_device.dart';
import '../models/upnp_device_description.dart';

sealed class SsdpEngineEvent {
  const SsdpEngineEvent();
}

class SsdpDeviceDiscovered extends SsdpEngineEvent {
  const SsdpDeviceDiscovered(
    this.device, {
    this.description,
    this.isUpdate = false,
  });

  final SsdpDevice device;
  final UpnpDeviceDescription? description;
  final bool isUpdate;
}

class SsdpDeviceExpired extends SsdpEngineEvent {
  const SsdpDeviceExpired(this.deviceKey);
  final String deviceKey;
}

class SsdpEngineWarning extends SsdpEngineEvent {
  const SsdpEngineWarning(this.message);
  final String message;
}

class SsdpDiscoveryEngine {
  SsdpDiscoveryEngine();

  Stream<SsdpEngineEvent> get events => const Stream<SsdpEngineEvent>.empty();
  int get rawObservationCount => 0;
  int get metadataFetchCount => 0;
  int get metadataFailureCount => 0;

  Future<void> start({
    required Set<String> searchTargets,
    required bool fetchUpnpDescriptions,
    required MetadataSecurityPolicy metadataSecurityPolicy,
    required bool includeLoopback,
    required bool includeLinkLocal,
    required bool includeVpnInterfaces,
    required bool includeCellularInterfaces,
    required bool includePeerToPeer,
    Duration searchInterval = const Duration(seconds: 30),
  }) {
    throw UnsupportedError('SSDP is unavailable on this platform');
  }

  Future<void> pause() async {}
  Future<void> resume() async {}
  Future<void> stop() async {}
}
