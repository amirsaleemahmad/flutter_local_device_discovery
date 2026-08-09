import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/metadata_security_policy.dart';
import '../models/ssdp_device.dart';
import '../models/upnp_device_description.dart';
import '../upnp/upnp_description_fetcher.dart';
import 'ssdp_message.dart';

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
  SsdpDiscoveryEngine({
    UpnpDescriptionFetcher fetcher = const UpnpDescriptionFetcher(),
  }) : _fetcher = fetcher;

  static final InternetAddress _multicastAddress = InternetAddress(
    '239.255.255.250',
  );
  static const int _multicastPort = 1900;

  final UpnpDescriptionFetcher _fetcher;
  final StreamController<SsdpEngineEvent> _controller =
      StreamController<SsdpEngineEvent>.broadcast();
  final List<RawDatagramSocket> _sockets = <RawDatagramSocket>[];
  final List<StreamSubscription<RawSocketEvent>> _subscriptions =
      <StreamSubscription<RawSocketEvent>>[];
  final Map<String, _SsdpRecord> _records = <String, _SsdpRecord>{};
  final Map<String, Future<UpnpDeviceDescription>> _metadataRequests =
      <String, Future<UpnpDeviceDescription>>{};

  Set<String> _searchTargets = const <String>{'ssdp:all'};
  bool _fetchDescriptions = false;
  MetadataSecurityPolicy _securityPolicy = MetadataSecurityPolicy.defaultPolicy;
  Timer? _searchTimer;
  Timer? _expiryTimer;
  bool _started = false;
  bool _paused = false;
  bool _stopped = false;

  int _rawObservationCount = 0;
  int _metadataFetchCount = 0;
  int _metadataFailureCount = 0;

  Stream<SsdpEngineEvent> get events => _controller.stream;
  int get rawObservationCount => _rawObservationCount;
  int get metadataFetchCount => _metadataFetchCount;
  int get metadataFailureCount => _metadataFailureCount;

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
  }) async {
    if (_started) return;
    _started = true;
    _fetchDescriptions = fetchUpnpDescriptions;
    _securityPolicy = metadataSecurityPolicy;
    _searchTargets = _sanitizeTargets(searchTargets);

    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: includeLoopback,
      includeLinkLocal: includeLinkLocal,
    );
    final selectedInterfaces = interfaces
        .where(
          (interface) => _includeInterface(
            interface.name,
            includeVpnInterfaces: includeVpnInterfaces,
            includeCellularInterfaces: includeCellularInterfaces,
            includePeerToPeer: includePeerToPeer,
          ),
        )
        .toList();

    for (final interface in selectedInterfaces) {
      for (final address in interface.addresses) {
        try {
          final socket = await RawDatagramSocket.bind(
            address,
            0,
            reuseAddress: true,
            reusePort: true,
          );
          _attachSocket(socket);
        } on SocketException catch (error) {
          _warn('Could not bind SSDP on ${interface.name}: ${error.message}');
        }
      }
    }

    if (_sockets.isEmpty) {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
        reusePort: true,
      );
      _attachSocket(socket);
    }

    await _startNotificationListener(selectedInterfaces);
    _sendSearches();

    final effectiveInterval = searchInterval < const Duration(seconds: 5)
        ? const Duration(seconds: 5)
        : searchInterval;
    _searchTimer = Timer.periodic(effectiveInterval, (_) => _sendSearches());
    _expiryTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _expireRecords(),
    );
  }

  Future<void> _startNotificationListener(
    List<NetworkInterface> interfaces,
  ) async {
    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _multicastPort,
        reuseAddress: true,
        reusePort: true,
      );
      var joined = false;
      for (final interface in interfaces) {
        try {
          socket.joinMulticast(_multicastAddress, interface);
          joined = true;
        } on Object {
          // Some virtual interfaces cannot join multicast; active search still
          // covers the default route and other interfaces.
        }
      }
      if (!joined) {
        socket.joinMulticast(_multicastAddress);
      }
      _attachSocket(socket);
    } on Object catch (error) {
      _warn(
        'Passive SSDP notifications are unavailable; active search remains '
        'enabled ($error)',
      );
    }
  }

  void _attachSocket(RawDatagramSocket socket) {
    socket
      ..multicastHops = 1
      ..readEventsEnabled = true;
    _sockets.add(socket);
    _subscriptions.add(
      socket.listen((event) {
        if (event != RawSocketEvent.read || _paused || _stopped) return;
        Datagram? datagram;
        while ((datagram = socket.receive()) != null) {
          _handleDatagram(datagram!);
        }
      }, onError: (Object error) => _warn('SSDP socket error: $error')),
    );
  }

  void _sendSearches() {
    if (_paused || _stopped) return;
    for (final target in _searchTargets) {
      final payload = ascii.encode(
        'M-SEARCH * HTTP/1.1\r\n'
        'HOST: 239.255.255.250:1900\r\n'
        'MAN: "ssdp:discover"\r\n'
        'MX: 2\r\n'
        'ST: $target\r\n'
        'USER-AGENT: flutter_local_device_discovery/0.2.0\r\n'
        '\r\n',
      );
      for (final socket in _sockets) {
        if (socket.port == _multicastPort) continue;
        try {
          socket.send(payload, _multicastAddress, _multicastPort);
        } on Object catch (error) {
          _warn('Could not send SSDP search for $target: $error');
        }
      }
    }
  }

  void _handleDatagram(Datagram datagram) {
    _rawObservationCount++;
    final message = SsdpMessageParser.tryParse(latin1.decode(datagram.data));
    if (message == null) return;
    final key = message.deviceKey;
    if (key == null) return;

    if (message.kind == SsdpMessageKind.byebye) {
      if (_records.remove(key) != null) {
        _controller.add(SsdpDeviceExpired(key));
      }
      return;
    }
    if (message.kind == SsdpMessageKind.unknown) return;

    final now = DateTime.now();
    final device = message.toDevice(
      sourceAddress: datagram.address.address,
      observedAt: now,
    );
    if (device == null) return;
    final existing = _records[key];
    final maxAge = device.cacheControlMaxAge ?? 1800;
    _records[key] = _SsdpRecord(
      device: device,
      expiresAt: now.add(Duration(seconds: maxAge.clamp(1, 86400))),
      description: existing?.description,
    );

    final changed = existing == null ||
        existing.device.location != device.location ||
        existing.device.searchTarget != device.searchTarget ||
        existing.device.bootId != device.bootId ||
        existing.device.configId != device.configId;
    if (changed) {
      _controller.add(SsdpDeviceDiscovered(device, isUpdate: existing != null));
    }
    if (_fetchDescriptions &&
        (existing == null ||
            existing.device.location != device.location ||
            existing.device.bootId != device.bootId ||
            existing.description == null)) {
      if (existing != null &&
          (existing.device.bootId != device.bootId ||
              existing.device.configId != device.configId)) {
        _metadataRequests.remove(device.location);
      }
      _fetchDescription(key, device);
    }
  }

  void _fetchDescription(String key, SsdpDevice device) {
    final uri = Uri.tryParse(device.location);
    if (uri == null) return;
    final request = _metadataRequests.putIfAbsent(device.location, () {
      _metadataFetchCount++;
      return _fetcher.fetch(uri, policy: _securityPolicy);
    });
    unawaited(_completeDescription(key, device, request));
  }

  Future<void> _completeDescription(
    String key,
    SsdpDevice device,
    Future<UpnpDeviceDescription> request,
  ) async {
    try {
      final description = await request;
      final current = _records[key];
      if (current == null || current.device.location != device.location) return;
      final enriched = current.device.copyWith(
        friendlyName: description.friendlyName,
        manufacturer: description.manufacturer,
        modelName: description.modelName,
        udn: description.udn,
        deviceType: description.deviceType,
      );
      _records[key] = current.copyWith(
        device: enriched,
        description: description,
      );
      _controller.add(
        SsdpDeviceDiscovered(
          enriched,
          description: description,
          isUpdate: true,
        ),
      );
    } on Object catch (error) {
      _metadataFailureCount++;
      _metadataRequests.remove(device.location);
      _warn(
        'UPnP metadata blocked or unavailable at ${device.location}: $error',
      );
    }
  }

  void _expireRecords() {
    if (_paused || _stopped) return;
    final now = DateTime.now();
    final expired = _records.entries
        .where((entry) => !entry.value.expiresAt.isAfter(now))
        .map((entry) => entry.key)
        .toList();
    for (final key in expired) {
      _records.remove(key);
      _controller.add(SsdpDeviceExpired(key));
    }
  }

  Set<String> _sanitizeTargets(Set<String> targets) {
    final valid = targets
        .map((target) => target.trim())
        .where(
          (target) =>
              target.isNotEmpty &&
              target.length <= 512 &&
              !target.contains('\r') &&
              !target.contains('\n'),
        )
        .toSet();
    return valid.isEmpty ? const <String>{'ssdp:all'} : valid;
  }

  bool _includeInterface(
    String name, {
    required bool includeVpnInterfaces,
    required bool includeCellularInterfaces,
    required bool includePeerToPeer,
  }) {
    final lower = name.toLowerCase();
    final isVpn = lower.contains('tun') ||
        lower.contains('tap') ||
        lower.contains('utun') ||
        lower.contains('vpn');
    final isCellular = lower.contains('pdp_ip') ||
        lower.contains('rmnet') ||
        lower.contains('wwan') ||
        lower.contains('cell');
    final isPeer = lower.contains('awdl') ||
        lower.contains('p2p') ||
        lower.contains('llw');
    return (includeVpnInterfaces || !isVpn) &&
        (includeCellularInterfaces || !isCellular) &&
        (includePeerToPeer || !isPeer);
  }

  void _warn(String message) {
    if (!_controller.isClosed) _controller.add(SsdpEngineWarning(message));
  }

  Future<void> pause() async {
    _paused = true;
  }

  Future<void> resume() async {
    if (_stopped) return;
    _paused = false;
    _sendSearches();
  }

  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;
    _searchTimer?.cancel();
    _expiryTimer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    for (final socket in _sockets) {
      socket.close();
    }
    _subscriptions.clear();
    _sockets.clear();
    _records.clear();
    await _controller.close();
  }
}

class _SsdpRecord {
  const _SsdpRecord({
    required this.device,
    required this.expiresAt,
    this.description,
  });

  final SsdpDevice device;
  final DateTime expiresAt;
  final UpnpDeviceDescription? description;

  _SsdpRecord copyWith({
    SsdpDevice? device,
    DateTime? expiresAt,
    UpnpDeviceDescription? description,
  }) {
    return _SsdpRecord(
      device: device ?? this.device,
      expiresAt: expiresAt ?? this.expiresAt,
      description: description ?? this.description,
    );
  }
}
