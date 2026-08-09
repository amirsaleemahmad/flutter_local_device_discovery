import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_device_discovery_platform_interface/flutter_local_device_discovery_platform_interface.dart';

import '../models/internet_address_value.dart';
import '../models/local_device.dart';
import '../models/local_device_capability.dart';
import '../models/local_device_identity.dart';
import '../models/local_device_type.dart';
import '../models/local_service.dart';
import '../ssdp/ssdp_discovery_engine.dart';
import '../web/web_impl.dart';
import 'device_aggregator.dart';
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
    if (kIsWeb) WebFlutterLocalDeviceDiscovery.registerWith();
  }

  static final _SharedDiscoveryDiagnostics _sharedDiagnostics =
      _SharedDiscoveryDiagnostics();

  /// Returns the capabilities supported by the current platform.
  Future<LocalDiscoveryCapabilities> getCapabilities() async {
    final native =
        await FlutterLocalDeviceDiscoveryPlatform.instance.getCapabilities();
    final protocols = native.supportedProtocols
        .map(_protocolFromInt)
        .whereType<LocalDiscoveryProtocol>()
        .toSet();
    if (!kIsWeb) {
      protocols
        ..add(LocalDiscoveryProtocol.ssdp)
        ..add(LocalDiscoveryProtocol.upnp);
    }
    return LocalDiscoveryCapabilities(
      supportedProtocols: protocols,
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
      platformDetails: <String, Object?>{
        ...native.platformDetails,
        'sharedSsdpEngine': !kIsWeb,
        'secureUpnpMetadata': !kIsWeb,
      },
    );
  }

  /// Performs bounded discovery and returns the final normalized snapshot.
  Future<LocalDiscoverySnapshot> discover(LocalDiscoveryRequest request) async {
    request.validate();
    final session = await start(request);
    try {
      return await session.snapshot();
    } finally {
      await session.stop();
    }
  }

  /// Starts a discovery session.
  Future<LocalDiscoverySession> start(LocalDiscoveryRequest request) async {
    request.validate();
    final platform = FlutterLocalDeviceDiscoveryPlatform.instance;
    final nativeRequest = _toNativeRequest(request);
    final ssdpEnabled = !kIsWeb &&
        (request.protocols.contains(LocalDiscoveryProtocol.ssdp) ||
            request.protocols.contains(LocalDiscoveryProtocol.upnp) ||
            request.ssdpSearchTargets.isNotEmpty);

    String? nativeSessionId;
    Stream<LocalDiscoveryEvent> nativeEvents =
        const Stream<LocalDiscoveryEvent>.empty();
    Object? nativeStartError;
    try {
      nativeSessionId = await platform.startDiscovery(nativeRequest);
      nativeEvents =
          platform.eventsForSession(nativeSessionId).map(_eventFromNative);
    } on Object catch (error) {
      nativeStartError = error;
      if (!ssdpEnabled) rethrow;
    }

    final id = nativeSessionId ??
        'dart-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    final session = _LocalDiscoverySessionImpl(
      id: id,
      nativeSessionId: nativeSessionId,
      request: request,
      platform: platform,
      nativeEvents: nativeEvents,
      ssdpEngine: ssdpEnabled ? SsdpDiscoveryEngine() : null,
      aggregator: DeviceAggregator(),
      sharedDiagnostics: _sharedDiagnostics,
    );
    await session.initialize(nativeStartError: nativeStartError);
    return session;
  }

  /// Checks whether discovery can start with the given request.
  Future<LocalDiscoveryReadiness> checkReadiness(
    LocalDiscoveryRequest request,
  ) async {
    request.validate();
    final native = await FlutterLocalDeviceDiscoveryPlatform.instance
        .checkReadiness(_toNativeRequest(request));
    final warnings = native.warnings.toSet();
    if (request.fetchUpnpDescriptions &&
        !request.protocols.contains(LocalDiscoveryProtocol.ssdp) &&
        !request.protocols.contains(LocalDiscoveryProtocol.upnp)) {
      warnings.add('upnp_metadata_requires_ssdp_or_upnp_protocol');
    }
    return LocalDiscoveryReadiness(
      canStart: native.canStart,
      requirements: native.requirements.toSet(),
      warnings: warnings,
      platformDetails: <String, Object?>{
        ...native.platformDetails,
        'ssdpRequested':
            request.protocols.contains(LocalDiscoveryProtocol.ssdp) ||
                request.protocols.contains(LocalDiscoveryProtocol.upnp),
      },
    );
  }

  /// Returns diagnostics from both the native and shared v0.2 engines.
  Future<LocalDiscoveryDiagnostics> getDiagnostics() async {
    final native =
        await FlutterLocalDeviceDiscoveryPlatform.instance.getDiagnostics();
    final supportedProtocols = native.supportedProtocols
        .map(_protocolFromInt)
        .whereType<LocalDiscoveryProtocol>()
        .toSet();
    if (!kIsWeb) {
      supportedProtocols
        ..add(LocalDiscoveryProtocol.ssdp)
        ..add(LocalDiscoveryProtocol.upnp);
    }
    return LocalDiscoveryDiagnostics(
      pluginVersion: '0.2.0',
      platformVersion: native.platformVersion,
      supportedProtocols: supportedProtocols,
      activeSessions: native.activeSessions > _sharedDiagnostics.activeSessions
          ? native.activeSessions
          : _sharedDiagnostics.activeSessions,
      networkInterfaces: native.networkInterfaces,
      multicastAvailable: native.multicastAvailable,
      localNetworkReady: native.localNetworkReady,
      rawObservationCount:
          native.rawObservationCount + _sharedDiagnostics.rawObservationCount,
      deduplicatedDeviceCount: _sharedDiagnostics.deduplicatedDeviceCount > 0
          ? _sharedDiagnostics.deduplicatedDeviceCount
          : native.deduplicatedDeviceCount,
      resolutionSuccessCount: native.resolutionSuccessCount,
      resolutionFailureCount: native.resolutionFailureCount,
      metadataFetchCount:
          native.metadataFetchCount + _sharedDiagnostics.metadataFetchCount,
      droppedEventCount:
          native.droppedEventCount + _sharedDiagnostics.droppedEventCount,
      lastNetworkChangeAt: native.lastNetworkChangeAt,
      warnings: <String>[...native.warnings, ..._sharedDiagnostics.warnings],
      platformDetails: <String, Object?>{
        ...native.platformDetails,
        'sharedSsdpEngine': !kIsWeb,
        'upnpMetadataFailureCount': _sharedDiagnostics.metadataFailureCount,
      },
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
      maxDevices: request.maxDevices,
      maxServices: request.maxServices,
      metadata: request.metadata,
    );
  }

  LocalDiscoveryEvent _eventFromNative(NativeDiscoveryEvent event) {
    return switch (event.type) {
      0 => const LocalDiscoveryStarted(),
      1 => LocalDeviceAdded(_deviceFromNative(event.device!)),
      2 => LocalDeviceUpdated(_deviceFromNative(event.device!)),
      3 => LocalDeviceRemoved(_deviceFromNative(event.device!)),
      4 => LocalServiceAdded(_serviceFromNative(event.service!)),
      5 => LocalServiceUpdated(_serviceFromNative(event.service!)),
      6 => LocalServiceRemoved(_serviceFromNative(event.service!)),
      7 => const LocalNetworkChanged(),
      8 => LocalDiscoveryWarning(event.errorMessage ?? 'Unknown warning'),
      9 => LocalDiscoveryFailure(
          event.errorMessage ?? event.errorCode ?? 'Unknown error',
        ),
      10 => const LocalDiscoveryStopped(),
      _ => LocalDiscoveryWarning('Unknown event type: ${event.type}'),
    };
  }

  LocalDevice _deviceFromNative(NativeDevice device) {
    final services = device.services.map(_serviceFromNative).toList();
    return LocalDevice(
      id: device.id,
      displayName: device.displayName,
      hostname: device.hostname,
      addresses: device.addresses
          .map(
            (address) => InternetAddressValue(
              address: address.address,
              family: address.family,
              scopeId: address.scopeId,
              interfaceName: address.interfaceName,
              isLoopback: address.isLoopback,
              isLinkLocal: address.isLinkLocal,
              isPrivate: address.isPrivate,
              isMulticast: address.isMulticast,
            ),
          )
          .toList(),
      services: services,
      type: _deviceTypeFromInt(device.type),
      capabilities: device.capabilities
          .map(_capabilityFromInt)
          .whereType<LocalDeviceCapability>()
          .toSet(),
      identity: LocalDeviceIdentity(
        macAddress: device.macAddress,
        serviceInstance: device.serviceInstance ??
            (services.isEmpty ? null : services.first.instanceName),
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
            (address) => InternetAddressValue(
              address: address.address,
              family: address.family,
              scopeId: address.scopeId,
              interfaceName: address.interfaceName,
              isLoopback: address.isLoopback,
              isLinkLocal: address.isLinkLocal,
              isPrivate: address.isPrivate,
              isMulticast: address.isMulticast,
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
      ttl: service.ttlSeconds == null
          ? null
          : Duration(seconds: service.ttlSeconds!),
      resolved: service.resolved,
      location:
          service.location == null ? null : Uri.tryParse(service.location!),
      metadata: service.metadata,
    );
  }

  static int _modeToInt(LocalDiscoveryMode mode) => mode.index;

  static int _protocolToInt(LocalDiscoveryProtocol protocol) => protocol.index;

  static LocalDiscoveryProtocol? _protocolFromInt(int value) =>
      value >= 0 && value < LocalDiscoveryProtocol.values.length
          ? LocalDiscoveryProtocol.values[value]
          : null;

  static LocalDeviceType _deviceTypeFromInt(int value) =>
      value >= 0 && value < LocalDeviceType.values.length
          ? LocalDeviceType.values[value]
          : LocalDeviceType.unknown;

  static LocalDeviceCapability? _capabilityFromInt(int value) =>
      value >= 0 && value < LocalDeviceCapability.values.length
          ? LocalDeviceCapability.values[value]
          : null;
}

class _LocalDiscoverySessionImpl implements LocalDiscoverySession {
  _LocalDiscoverySessionImpl({
    required this.id,
    required this.nativeSessionId,
    required this.request,
    required this.platform,
    required this.nativeEvents,
    required this.ssdpEngine,
    required this.aggregator,
    required this.sharedDiagnostics,
  });

  @override
  final String id;
  final String? nativeSessionId;
  @override
  final LocalDiscoveryRequest request;
  final FlutterLocalDeviceDiscoveryPlatform platform;
  final Stream<LocalDiscoveryEvent> nativeEvents;
  final SsdpDiscoveryEngine? ssdpEngine;
  final DeviceAggregator aggregator;
  final _SharedDiscoveryDiagnostics sharedDiagnostics;

  final StreamController<LocalDiscoveryEvent> _controller =
      StreamController<LocalDiscoveryEvent>.broadcast();
  final Map<String, LocalDevice> _rawDevices = <String, LocalDevice>{};
  final Map<String, LocalDevice> _visibleDevices = <String, LocalDevice>{};
  final Map<String, LocalService> _services = <String, LocalService>{};
  final Completer<void> _stopped = Completer<void>();
  StreamSubscription<LocalDiscoveryEvent>? _nativeSubscription;
  StreamSubscription<SsdpEngineEvent>? _ssdpSubscription;
  LocalDiscoverySessionState _state = LocalDiscoverySessionState.created;
  DateTime? _startedAt;
  int _lastSsdpObservationCount = 0;
  int _lastMetadataFetchCount = 0;
  int _lastMetadataFailureCount = 0;

  @override
  LocalDiscoverySessionState get state => _state;

  @override
  Stream<LocalDiscoveryEvent> get events => _controller.stream;

  Future<void> initialize({Object? nativeStartError}) async {
    _state = LocalDiscoverySessionState.starting;
    _startedAt = DateTime.now();
    sharedDiagnostics.sessionStarted();
    _nativeSubscription = nativeEvents.listen(
      _handleNativeEvent,
      onError: (Object error) => _warning('Native event stream failed: $error'),
    );

    if (ssdpEngine != null) {
      _ssdpSubscription = ssdpEngine!.events.listen(
        _handleSsdpEvent,
        onError: (Object error) => _warning('SSDP engine failed: $error'),
      );
      try {
        final interval = request.mode == LocalDiscoveryMode.continuous
            ? const Duration(seconds: 30)
            : Duration(seconds: (request.duration.inSeconds ~/ 2).clamp(5, 30));
        await ssdpEngine!.start(
          searchTargets: request.ssdpSearchTargets,
          fetchUpnpDescriptions: request.fetchUpnpDescriptions,
          metadataSecurityPolicy: request.metadataSecurityPolicy,
          includeLoopback: request.includeLoopback,
          includeLinkLocal: request.includeLinkLocal,
          includeVpnInterfaces: request.includeVpnInterfaces,
          includeCellularInterfaces: request.includeCellularInterfaces,
          includePeerToPeer: request.includePeerToPeer,
          searchInterval: interval,
        );
      } on Object catch (error) {
        _warning('SSDP could not start: $error');
      }
    }
    if (nativeStartError != null) {
      _warning('Native discovery could not start: $nativeStartError');
    }
    _state = LocalDiscoverySessionState.running;
    _emit(const LocalDiscoveryStarted());
  }

  void _handleNativeEvent(LocalDiscoveryEvent event) {
    switch (event) {
      case LocalDiscoveryStarted():
      case LocalDiscoveryStopped():
        return;
      case LocalDeviceAdded(:final device):
      case LocalDeviceUpdated(:final device):
        final key = 'native:${device.id}';
        final existing = _rawDevices[key];
        _rawDevices[key] = existing == null
            ? device
            : aggregator.mergeDevices(existing, device);
        _rebuildDevices();
      case LocalDeviceRemoved(:final device):
        _rawDevices.remove('native:${device.id}');
        _rebuildDevices();
      case LocalServiceAdded(:final service):
        _upsertService(service, added: true);
      case LocalServiceUpdated(:final service):
        _upsertService(service, added: false);
      case LocalServiceRemoved(:final service):
        _removeService(service);
      case LocalNetworkChanged():
        if (request.monitorNetworkChanges) _emit(event);
      case LocalDiscoveryWarning(:final message):
        _warning(message);
      case LocalDiscoveryFailure():
        _emit(event);
    }
  }

  void _handleSsdpEvent(SsdpEngineEvent event) {
    _syncSsdpMetrics();
    switch (event) {
      case SsdpDeviceDiscovered(:final device, :final description):
        final rootKey = device.usn.split('::').first.toLowerCase();
        final key = 'ssdp:$rootKey';
        var normalized = aggregator.mergeSsdpDevice(
          existing: _rawDevices[key],
          ssdp: device,
          discoveredBy: 'ssdp',
        );
        if (description != null) {
          normalized = aggregator.enrichWithUpnp(
            device: normalized,
            description: description,
          );
        }
        _rawDevices[key] = normalized;
        _rebuildDevices();
      case SsdpDeviceExpired(:final deviceKey):
        _rawDevices.remove('ssdp:${deviceKey.toLowerCase()}');
        _rebuildDevices();
      case SsdpEngineWarning(:final message):
        _warning(message);
    }
  }

  void _upsertService(LocalService service, {required bool added}) {
    final alreadyExists = _services.containsKey(service.id);
    if (!alreadyExists && _services.length >= request.maxServices) {
      sharedDiagnostics.droppedEventCount++;
      return;
    }
    _services[service.id] = service;
    _attachServiceToDevices(service);
    if (_includesServices) {
      _emit(
        added && !alreadyExists
            ? LocalServiceAdded(service)
            : LocalServiceUpdated(service),
      );
    }
  }

  void _removeService(LocalService service) {
    final removed = _services.remove(service.id);
    for (final entry in _rawDevices.entries.toList()) {
      if (entry.value.services.any((item) => item.id == service.id)) {
        _rawDevices[entry.key] = entry.value.copyWith(
          services: entry.value.services
              .where((item) => item.id != service.id)
              .toList(),
        );
      }
    }
    _rebuildDevices();
    if (_includesServices && removed != null) {
      _emit(LocalServiceRemoved(removed));
    }
  }

  void _attachServiceToDevices(LocalService service) {
    for (final entry in _rawDevices.entries.toList()) {
      final device = entry.value;
      final matches = device.services.any(
            (item) =>
                item.id == service.id ||
                item.instanceName == service.instanceName,
          ) ||
          device.identity.serviceInstance == service.instanceName;
      if (!matches) continue;
      final services = <String, LocalService>{
        for (final item in device.services) item.id: item,
        service.id: service,
      };
      _rawDevices[entry.key] = device.copyWith(
        services: services.values.toList(growable: false),
      );
    }
    _rebuildDevices();
  }

  void _rebuildDevices() {
    var devices = request.deduplicateResults
        ? aggregator.aggregate(_rawDevices.values.toList())
        : _rawDevices.values
            .map(
              request.classifyDevices
                  ? aggregator.enrichFromServices
                  : (device) => device,
            )
            .toList();
    if (!request.classifyDevices) {
      devices = devices
          .map(
            (device) => device.copyWith(
              type: LocalDeviceType.unknown,
              capabilities: const <LocalDeviceCapability>{},
              capabilityEvidence: const [],
              confidence: 0,
            ),
          )
          .toList();
    }
    final filter = request.filter;
    if (filter != null) devices = devices.where(filter.matches).toList();
    if (devices.length > request.maxDevices) {
      sharedDiagnostics.droppedEventCount +=
          devices.length - request.maxDevices;
      devices = devices.take(request.maxDevices).toList();
    }

    final next = <String, LocalDevice>{
      for (final device in devices) device.id: device,
    };
    if (_includesDevices) {
      for (final entry in _visibleDevices.entries) {
        if (!next.containsKey(entry.key)) {
          _emit(LocalDeviceRemoved(entry.value));
        }
      }
      for (final entry in next.entries) {
        final previous = _visibleDevices[entry.key];
        if (previous == null) {
          _emit(LocalDeviceAdded(entry.value));
        } else if (!_equivalent(previous, entry.value)) {
          _emit(LocalDeviceUpdated(entry.value));
        }
      }
    }
    _visibleDevices
      ..clear()
      ..addAll(next);
    sharedDiagnostics.deduplicatedDeviceCount = _visibleDevices.length;
  }

  bool _equivalent(LocalDevice a, LocalDevice b) {
    return a.displayName == b.displayName &&
        a.hostname == b.hostname &&
        a.type == b.type &&
        a.confidence == b.confidence &&
        _setEquals(a.capabilities, b.capabilities) &&
        _setEquals(a.discoveredBy, b.discoveredBy) &&
        _setEquals(
          a.addresses.map((address) => address.address).toSet(),
          b.addresses.map((address) => address.address).toSet(),
        ) &&
        _setEquals(
          a.services
              .map((service) => '${service.id}:${service.resolved}')
              .toSet(),
          b.services
              .map((service) => '${service.id}:${service.resolved}')
              .toSet(),
        ) &&
        a.identity == b.identity &&
        a.metadata.toString() == b.metadata.toString();
  }

  bool _setEquals<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);

  bool get _includesDevices => request.mode != LocalDiscoveryMode.servicesOnly;
  bool get _includesServices => request.mode != LocalDiscoveryMode.devicesOnly;

  void _syncSsdpMetrics() {
    final engine = ssdpEngine;
    if (engine == null) return;
    final rawDelta = engine.rawObservationCount - _lastSsdpObservationCount;
    final fetchDelta = engine.metadataFetchCount - _lastMetadataFetchCount;
    final failureDelta =
        engine.metadataFailureCount - _lastMetadataFailureCount;
    if (rawDelta > 0) sharedDiagnostics.rawObservationCount += rawDelta;
    if (fetchDelta > 0) sharedDiagnostics.metadataFetchCount += fetchDelta;
    if (failureDelta > 0) {
      sharedDiagnostics.metadataFailureCount += failureDelta;
    }
    _lastSsdpObservationCount = engine.rawObservationCount;
    _lastMetadataFetchCount = engine.metadataFetchCount;
    _lastMetadataFailureCount = engine.metadataFailureCount;
  }

  void _warning(String message) {
    sharedDiagnostics.addWarning(message);
    _emit(LocalDiscoveryWarning(message));
  }

  void _emit(LocalDiscoveryEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  @override
  Future<LocalDiscoverySnapshot> snapshot() async {
    final startedAt = _startedAt ?? DateTime.now();
    final remaining =
        startedAt.add(request.duration).difference(DateTime.now());
    if (remaining > Duration.zero &&
        _state != LocalDiscoverySessionState.stopped) {
      await Future.any<void>(<Future<void>>[
        Future<void>.delayed(remaining),
        _stopped.future,
      ]);
    }
    final completedAt = DateTime.now();
    return LocalDiscoverySnapshot(
      sessionId: id,
      devices: _includesDevices
          ? List<LocalDevice>.unmodifiable(_visibleDevices.values)
          : const <LocalDevice>[],
      services: _includesServices
          ? List<LocalService>.unmodifiable(_services.values)
          : const <LocalService>[],
      startedAt: startedAt,
      completedAt: completedAt,
      duration: completedAt.difference(startedAt),
    );
  }

  @override
  Future<void> pause() async {
    if (_state != LocalDiscoverySessionState.running) return;
    if (nativeSessionId != null) {
      await platform.pauseDiscovery(nativeSessionId!);
    }
    await ssdpEngine?.pause();
    _state = LocalDiscoverySessionState.paused;
  }

  @override
  Future<void> resume() async {
    if (_state != LocalDiscoverySessionState.paused) return;
    if (nativeSessionId != null) {
      await platform.resumeDiscovery(nativeSessionId!);
    }
    await ssdpEngine?.resume();
    _state = LocalDiscoverySessionState.running;
  }

  @override
  Future<void> stop() async {
    if (_state == LocalDiscoverySessionState.stopped ||
        _state == LocalDiscoverySessionState.stopping) {
      return;
    }
    _state = LocalDiscoverySessionState.stopping;
    _syncSsdpMetrics();
    await _ssdpSubscription?.cancel();
    await ssdpEngine?.stop();
    if (nativeSessionId != null) {
      try {
        await platform.stopDiscovery(nativeSessionId!);
      } on Object catch (error) {
        _warning('Native discovery did not stop cleanly: $error');
      }
    }
    await _nativeSubscription?.cancel();
    _state = LocalDiscoverySessionState.stopped;
    sharedDiagnostics.sessionStopped();
    _emit(const LocalDiscoveryStopped());
    if (!_stopped.isCompleted) _stopped.complete();
    await _controller.close();
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

  final bool canStart;
  final Set<String> requirements;
  final Set<String> warnings;
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

  final String? pluginVersion;
  final String? platformVersion;
  final Set<LocalDiscoveryProtocol> supportedProtocols;
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
}

class _SharedDiscoveryDiagnostics {
  int activeSessions = 0;
  int rawObservationCount = 0;
  int deduplicatedDeviceCount = 0;
  int metadataFetchCount = 0;
  int metadataFailureCount = 0;
  int droppedEventCount = 0;
  final List<String> warnings = <String>[];

  void sessionStarted() => activeSessions++;

  void sessionStopped() {
    if (activeSessions > 0) activeSessions--;
  }

  void addWarning(String warning) {
    if (warnings.contains(warning)) return;
    warnings.add(warning);
    if (warnings.length > 20) warnings.removeAt(0);
  }
}
