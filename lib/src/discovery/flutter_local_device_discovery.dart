import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_device_discovery_platform_interface/flutter_local_device_discovery_platform_interface.dart';

import '../models/internet_address_value.dart';
import '../web/web_impl.dart';
import '../models/local_device.dart';
import '../models/local_device_capability.dart';
import '../models/local_device_identity.dart';
import '../models/local_device_type.dart';
import '../models/local_service.dart';
import 'local_discovery_capabilities.dart';
import 'local_discovery_event.dart';
import 'local_discovery_mode.dart';
import 'local_discovery_protocol.dart';
import 'local_discovery_request.dart';
import 'local_discovery_session.dart';

/// The main entry point for local device discovery.
class FlutterLocalDeviceDiscovery {
  /// Creates a new [FlutterLocalDeviceDiscovery] instance.
  FlutterLocalDeviceDiscovery() {
    if (kIsWeb) {
      WebFlutterLocalDeviceDiscovery.registerWith();
    }
  }

  /// Returns the capabilities supported by the current platform.
  Future<LocalDiscoveryCapabilities> getCapabilities() async {
    final native = await FlutterLocalDeviceDiscoveryPlatform.instance
        .getCapabilities();
    return LocalDiscoveryCapabilities(
      supportedProtocols: native.supportedProtocols
          .map(_protocolFromInt)
          .whereType<LocalDiscoveryProtocol>()
          .toSet(),
      supportsServiceRegistration: native.supportsServiceRegistration,
      supportsIpv4: native.supportsIpv4,
      supportsIpv6: native.supportsIpv6,
      supportsMultipleInterfaces: native.supportsMultipleInterfaces,
      supportsNetworkSpecificDiscovery: native.supportsNetworkSpecificDiscovery,
      supportsNeighborTable: native.supportsNeighborTable,
      supportsReachability: native.supportsReachability,
      supportsSafePortProbe: native.supportsSafePortProbe,
      requiresLocalNetworkPermission: native.requiresLocalNetworkPermission,
      requiresMulticastPermission: native.requiresMulticastPermission,
      platformDetails: native.platformDetails,
    );
  }

  /// Performs a snapshot discovery and returns the result.
  ///
  /// The discovery runs for [LocalDiscoveryRequest.duration] and returns
  /// a deduplicated snapshot of discovered devices and services.
  Future<LocalDiscoverySnapshot> discover(
    LocalDiscoveryRequest request,
  ) async {
    request.validate();
    final session = await start(request);
    try {
      return await session.snapshot();
    } finally {
      await session.stop();
    }
  }

  /// Starts a discovery session.
  ///
  /// The session continues until [LocalDiscoverySession.stop] is called.
  Future<LocalDiscoverySession> start(
    LocalDiscoveryRequest request,
  ) async {
    request.validate();
    final nativeRequest = _toNativeRequest(request);
    final sessionId = await FlutterLocalDeviceDiscoveryPlatform.instance
        .startDiscovery(nativeRequest);

    final events = FlutterLocalDeviceDiscoveryPlatform.instance
        .eventsForSession(sessionId);

    return _LocalDiscoverySessionImpl(
      id: sessionId,
      request: request,
      events: events.map(_eventFromNative),
    );
  }

  /// Checks whether discovery can start with the given request.
  Future<LocalDiscoveryReadiness> checkReadiness(
    LocalDiscoveryRequest request,
  ) async {
    final native = await FlutterLocalDeviceDiscoveryPlatform.instance
        .checkReadiness(_toNativeRequest(request));
    return LocalDiscoveryReadiness(
      canStart: native.canStart,
      requirements: native.requirements.toSet(),
      warnings: native.warnings.toSet(),
      platformDetails: native.platformDetails,
    );
  }

  /// Returns diagnostics about the discovery engine.
  Future<LocalDiscoveryDiagnostics> getDiagnostics() async {
    final native = await FlutterLocalDeviceDiscoveryPlatform.instance
        .getDiagnostics();
    return LocalDiscoveryDiagnostics(
      pluginVersion: native.pluginVersion,
      platformVersion: native.platformVersion,
      supportedProtocols: native.supportedProtocols
          .map(_protocolFromInt)
          .whereType<LocalDiscoveryProtocol>()
          .toSet(),
      activeSessions: native.activeSessions,
      networkInterfaces: native.networkInterfaces,
      multicastAvailable: native.multicastAvailable,
      localNetworkReady: native.localNetworkReady,
      rawObservationCount: native.rawObservationCount,
      deduplicatedDeviceCount: native.deduplicatedDeviceCount,
      resolutionSuccessCount: native.resolutionSuccessCount,
      resolutionFailureCount: native.resolutionFailureCount,
      metadataFetchCount: native.metadataFetchCount,
      droppedEventCount: native.droppedEventCount,
      lastNetworkChangeAt: native.lastNetworkChangeAt,
      warnings: native.warnings,
      platformDetails: native.platformDetails,
    );
  }

  NativeDiscoveryRequest _toNativeRequest(LocalDiscoveryRequest request) {
    return NativeDiscoveryRequest(
      mode: _modeToInt(request.mode),
      protocols: request.protocols.map(_protocolToInt).toList(),
      serviceTypes: request.serviceTypes.toList(),
      ssdpSearchTargets: request.ssdpSearchTargets.toList(),
      wsDiscoveryTypes: request.wsDiscoveryTypes.toList(),
      durationMilliseconds: request.duration.inMilliseconds,
      resolveTimeoutMilliseconds: request.resolveTimeout.inMilliseconds,
      metadataTimeoutMilliseconds: request.metadataTimeout.inMilliseconds,
      lostDeviceGracePeriodMilliseconds:
          request.lostDeviceGracePeriod.inMilliseconds,
      resolveServices: request.resolveServices,
      fetchUpnpDescriptions: request.fetchUpnpDescriptions,
      includeIpv4: request.includeIpv4,
      includeIpv6: request.includeIpv6,
      includeLoopback: request.includeLoopback,
      includeLinkLocal: request.includeLinkLocal,
      includeVpnInterfaces: request.includeVpnInterfaces,
      includeCellularInterfaces: request.includeCellularInterfaces,
      includePeerToPeer: request.includePeerToPeer,
      deduplicateResults: request.deduplicateResults,
      classifyDevices: request.classifyDevices,
      monitorNetworkChanges: request.monitorNetworkChanges,
      metadata: request.metadata,
    );
  }

  LocalDiscoveryEvent _eventFromNative(NativeDiscoveryEvent event) {
    switch (event.type) {
      case 0:
        return const LocalDiscoveryStarted();
      case 1:
        return LocalDeviceAdded(_deviceFromNative(event.device!));
      case 2:
        return LocalDeviceUpdated(_deviceFromNative(event.device!));
      case 3:
        return LocalDeviceRemoved(_deviceFromNative(event.device!));
      case 4:
        return LocalServiceAdded(_serviceFromNative(event.service!));
      case 5:
        return LocalServiceUpdated(_serviceFromNative(event.service!));
      case 6:
        return LocalServiceRemoved(_serviceFromNative(event.service!));
      case 7:
        return const LocalNetworkChanged();
      case 8:
        return LocalDiscoveryWarning(event.errorMessage ?? 'Unknown warning');
      case 9:
        return LocalDiscoveryFailure(
          event.errorMessage ?? event.errorCode ?? 'Unknown error',
        );
      case 10:
        return const LocalDiscoveryStopped();
      default:
        return LocalDiscoveryWarning('Unknown event type: ${event.type}');
    }
  }

  LocalDevice _deviceFromNative(NativeDevice device) {
    return LocalDevice(
      id: device.id,
      displayName: device.displayName,
      hostname: device.hostname,
      addresses: device.addresses
          .map(
            (a) => InternetAddressValue(
              address: a.address,
              family: a.family,
              scopeId: a.scopeId,
              interfaceName: a.interfaceName,
              isLoopback: a.isLoopback,
              isLinkLocal: a.isLinkLocal,
              isPrivate: a.isPrivate,
              isMulticast: a.isMulticast,
            ),
          )
          .toList(),
      services: device.services.map(_serviceFromNative).toList(),
      type: _deviceTypeFromInt(device.type),
      capabilities: device.capabilities
          .map(_capabilityFromInt)
          .whereType<LocalDeviceCapability>()
          .toSet(),
      identity: LocalDeviceIdentity(
        macAddress: device.macAddress,
        serviceInstance: device.serviceInstance,
        uniqueDeviceName: device.uniqueDeviceName,
        upnpUdn: device.upnpUdn,
        wsEndpointReference: device.wsEndpointReference,
        serialNumber: device.serialNumber,
        model: device.model,
        manufacturer: device.manufacturer,
        identifiers: device.identifiers,
      ),
      discoveredBy: device.protocols
          .map(_protocolFromInt)
          .whereType<LocalDiscoveryProtocol>()
          .toSet(),
      firstSeenAt: device.firstSeenAt,
      lastSeenAt: device.lastSeenAt,
      confidence: device.confidence,
      metadata: device.metadata,
    );
  }

  LocalService _serviceFromNative(NativeService service) {
    return LocalService(
      id: service.id,
      instanceName: service.instanceName,
      serviceType: service.serviceType,
      domain: service.domain,
      hostname: service.hostname,
      addresses: service.addresses
          .map(
            (a) => InternetAddressValue(
              address: a.address,
              family: a.family,
              scopeId: a.scopeId,
              interfaceName: a.interfaceName,
              isLoopback: a.isLoopback,
              isLinkLocal: a.isLinkLocal,
              isPrivate: a.isPrivate,
              isMulticast: a.isMulticast,
            ),
          )
          .toList(),
      port: service.port,
      transport: service.transport == 0
          ? LocalTransportProtocol.tcp
          : LocalTransportProtocol.udp,
      rawTxtRecords: service.rawTxtRecords,
      textTxtRecords: service.textTxtRecords,
      discoveredBy: service.protocols
          .map(_protocolFromInt)
          .whereType<LocalDiscoveryProtocol>()
          .toSet(),
      firstSeenAt: service.firstSeenAt,
      lastSeenAt: service.lastSeenAt,
      ttl: service.ttlSeconds != null
          ? Duration(seconds: service.ttlSeconds!)
          : null,
      resolved: service.resolved,
      location: service.location != null ? Uri.tryParse(service.location!) : null,
      metadata: service.metadata,
    );
  }

  static int _modeToInt(LocalDiscoveryMode mode) {
    switch (mode) {
      case LocalDiscoveryMode.servicesOnly:
        return 0;
      case LocalDiscoveryMode.devicesOnly:
        return 1;
      case LocalDiscoveryMode.servicesAndDevices:
        return 2;
      case LocalDiscoveryMode.continuous:
        return 3;
      case LocalDiscoveryMode.snapshot:
        return 4;
    }
  }

  static int _protocolToInt(LocalDiscoveryProtocol protocol) {
    switch (protocol) {
      case LocalDiscoveryProtocol.mdns:
        return 0;
      case LocalDiscoveryProtocol.dnsSd:
        return 1;
      case LocalDiscoveryProtocol.bonjour:
        return 2;
      case LocalDiscoveryProtocol.ssdp:
        return 3;
      case LocalDiscoveryProtocol.upnp:
        return 4;
      case LocalDiscoveryProtocol.wsDiscovery:
        return 5;
      case LocalDiscoveryProtocol.neighborTable:
        return 6;
      case LocalDiscoveryProtocol.reachability:
        return 7;
      case LocalDiscoveryProtocol.safePortProbe:
        return 8;
    }
  }

  static LocalDiscoveryProtocol? _protocolFromInt(int value) {
    switch (value) {
      case 0:
        return LocalDiscoveryProtocol.mdns;
      case 1:
        return LocalDiscoveryProtocol.dnsSd;
      case 2:
        return LocalDiscoveryProtocol.bonjour;
      case 3:
        return LocalDiscoveryProtocol.ssdp;
      case 4:
        return LocalDiscoveryProtocol.upnp;
      case 5:
        return LocalDiscoveryProtocol.wsDiscovery;
      case 6:
        return LocalDiscoveryProtocol.neighborTable;
      case 7:
        return LocalDiscoveryProtocol.reachability;
      case 8:
        return LocalDiscoveryProtocol.safePortProbe;
      default:
        return null;
    }
  }

  static LocalDeviceType _deviceTypeFromInt(int value) {
    if (value < 0 || value >= LocalDeviceType.values.length) {
      return LocalDeviceType.unknown;
    }
    return LocalDeviceType.values[value];
  }

  static LocalDeviceCapability? _capabilityFromInt(int value) {
    if (value < 0 || value >= LocalDeviceCapability.values.length) {
      return null;
    }
    return LocalDeviceCapability.values[value];
  }
}

/// A concrete implementation of [LocalDiscoverySession].
class _LocalDiscoverySessionImpl implements LocalDiscoverySession {
  _LocalDiscoverySessionImpl({
    required this.id,
    required this.request,
    required this._events,
  });

  @override
  final String id;

  @override
  final LocalDiscoveryRequest request;

  final Stream<LocalDiscoveryEvent> _events;

  LocalDiscoverySessionState _state = LocalDiscoverySessionState.created;

  @override
  LocalDiscoverySessionState get state => _state;

  @override
  Stream<LocalDiscoveryEvent> get events => _events;

  @override
  Future<LocalDiscoverySnapshot> snapshot() async {
    final devices = <LocalDevice>[];
    final services = <LocalService>[];
    final startedAt = DateTime.now();

    // Collect events for the remaining duration of the request.
    final deadline = DateTime.now().add(request.duration);
    final completer = Completer<void>();

    final subscription = _events.listen(
      (event) {
        switch (event) {
          case LocalDeviceAdded(:final device):
            devices.add(device);
          case LocalDeviceUpdated(:final device):
            final index = devices.indexWhere((d) => d.id == device.id);
            if (index >= 0) {
              devices[index] = device;
            } else {
              devices.add(device);
            }
          case LocalServiceAdded(:final service):
            services.add(service);
          case LocalServiceUpdated(:final service):
            final index = services.indexWhere((s) => s.id == service.id);
            if (index >= 0) {
              services[index] = service;
            } else {
              services.add(service);
            }
          default:
            break;
        }
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
      onError: (Object error) {
        if (!completer.isCompleted) completer.complete();
      },
    );

    // Wait until the deadline or the stream closes, whichever comes first.
    final remaining = deadline.difference(DateTime.now());
    if (remaining > Duration.zero) {
      await Future.any([
        completer.future,
        Future<void>.delayed(remaining),
      ]);
    }

    await subscription.cancel();

    return LocalDiscoverySnapshot(
      sessionId: id,
      devices: devices,
      services: services,
      startedAt: startedAt,
      completedAt: DateTime.now(),
    );
  }

  @override
  Future<void> pause() async {
    _state = LocalDiscoverySessionState.paused;
    await FlutterLocalDeviceDiscoveryPlatform.instance.pauseDiscovery(id);
  }

  @override
  Future<void> resume() async {
    _state = LocalDiscoverySessionState.running;
    await FlutterLocalDeviceDiscoveryPlatform.instance.resumeDiscovery(id);
  }

  @override
  Future<void> stop() async {
    if (_state == LocalDiscoverySessionState.stopped) return;
    _state = LocalDiscoverySessionState.stopping;
    await FlutterLocalDeviceDiscoveryPlatform.instance.stopDiscovery(id);
    _state = LocalDiscoverySessionState.stopped;
  }
}

/// Readiness information for a discovery request.
class LocalDiscoveryReadiness {
  const LocalDiscoveryReadiness({
    required this.canStart,
    this.requirements = const <String>{},
    this.warnings = const <String>{},
    this.platformDetails = const <String, Object?>{},
  });

  /// Whether discovery can start.
  final bool canStart;

  /// Requirements that must be met before discovery can start.
  final Set<String> requirements;

  /// Warnings about the discovery configuration.
  final Set<String> warnings;

  /// Platform-specific details.
  final Map<String, Object?> platformDetails;
}

/// Diagnostics about the discovery engine.
class LocalDiscoveryDiagnostics {
  const LocalDiscoveryDiagnostics({
    this.pluginVersion,
    this.platformVersion,
    this.supportedProtocols = const <LocalDiscoveryProtocol>{},
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

  /// The plugin version.
  final String? pluginVersion;

  /// The platform version.
  final String? platformVersion;

  /// The protocols supported by this platform.
  final Set<LocalDiscoveryProtocol> supportedProtocols;

  /// The number of active sessions.
  final int activeSessions;

  /// The names of network interfaces.
  final List<String> networkInterfaces;

  /// Whether multicast is available.
  final bool multicastAvailable;

  /// Whether the local network is ready.
  final bool localNetworkReady;

  /// The number of raw observations.
  final int rawObservationCount;

  /// The number of deduplicated devices.
  final int deduplicatedDeviceCount;

  /// The number of successful service resolutions.
  final int resolutionSuccessCount;

  /// The number of failed service resolutions.
  final int resolutionFailureCount;

  /// The number of metadata fetches.
  final int metadataFetchCount;

  /// The number of dropped events.
  final int droppedEventCount;

  /// When the last network change occurred.
  final DateTime? lastNetworkChangeAt;

  /// Recent warnings.
  final List<String> warnings;

  /// Platform-specific details.
  final Map<String, Object?> platformDetails;
}