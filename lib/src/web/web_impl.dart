import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_device_discovery_platform_interface/flutter_local_device_discovery_platform_interface.dart';

/// Web implementation of [FlutterLocalDeviceDiscoveryPlatform].
///
/// Web browsers do not support native mDNS/DNS-SD/Bonjour discovery.
/// This implementation provides graceful degradation with clear
/// capability reporting so applications can handle web gracefully.
class WebFlutterLocalDeviceDiscovery
    extends FlutterLocalDeviceDiscoveryPlatform {
  /// Registers the web implementation as the platform instance.
  static void registerWith() {
    if (kIsWeb) {
      FlutterLocalDeviceDiscoveryPlatform.instance =
          WebFlutterLocalDeviceDiscovery();
    }
  }

  @override
  Future<NativeDiscoveryCapabilities> getCapabilities() async {
    return const NativeDiscoveryCapabilities(
      supportedProtocols: <int>[],
      supportsServiceRegistration: false,
      supportsIpv4: false,
      supportsIpv6: false,
      supportsMultipleInterfaces: false,
      supportsNetworkSpecificDiscovery: false,
      supportsNeighborTable: false,
      supportsReachability: false,
      supportsSafePortProbe: false,
      requiresLocalNetworkPermission: false,
      requiresMulticastPermission: false,
      platformDetails: <String, Object?>{
        'platform': 'web',
        'note': 'Web browsers do not support native mDNS/DNS-SD discovery. '
            'Use a native platform (Android, iOS, macOS, Windows) for discovery.',
      },
    );
  }

  @override
  Future<NativeDiscoveryReadiness> checkReadiness(
    NativeDiscoveryRequest request,
  ) async {
    return const NativeDiscoveryReadiness(
      canStart: false,
      requirements: <String>['web_unsupported'],
      warnings: <String>[
        'Web browsers do not support native mDNS/DNS-SD discovery.',
      ],
      platformDetails: <String, Object?>{'platform': 'web'},
    );
  }

  @override
  Future<String> startDiscovery(NativeDiscoveryRequest request) async {
    throw UnsupportedError(
      'Local device discovery is not supported on web. '
      'Use a native platform (Android, iOS, macOS, Windows).',
    );
  }

  @override
  Stream<NativeDiscoveryEvent> eventsForSession(String sessionId) {
    return const Stream<NativeDiscoveryEvent>.empty();
  }

  @override
  Future<void> pauseDiscovery(String sessionId) async {
    // No-op on web.
  }

  @override
  Future<void> resumeDiscovery(String sessionId) async {
    // No-op on web.
  }

  @override
  Future<void> stopDiscovery(String sessionId) async {
    // No-op on web.
  }

  @override
  Future<NativeServiceRegistrationResult> registerService(
    NativeServiceRegistration request,
  ) async {
    throw UnsupportedError('Service registration is not supported on web.');
  }

  @override
  Future<void> updateRegisteredService(
    String registrationId,
    Map<String, dynamic> txtRecords,
  ) async {
    // No-op on web.
  }

  @override
  Future<void> unregisterService(String registrationId) async {
    // No-op on web.
  }

  @override
  Future<NativeDiscoveryDiagnostics> getDiagnostics() async {
    return const NativeDiscoveryDiagnostics(
      pluginVersion: '0.2.0',
      platformVersion: 'web',
      supportedProtocols: <int>[],
      activeSessions: 0,
      networkInterfaces: <String>[],
      multicastAvailable: false,
      localNetworkReady: false,
      rawObservationCount: 0,
      deduplicatedDeviceCount: 0,
      resolutionSuccessCount: 0,
      resolutionFailureCount: 0,
      metadataFetchCount: 0,
      droppedEventCount: 0,
      warnings: <String>[
        'Web browsers do not support native mDNS/DNS-SD discovery.',
      ],
      platformDetails: <String, Object?>{'platform': 'web'},
    );
  }
}
