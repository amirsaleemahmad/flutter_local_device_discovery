import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import '../models/metadata_security_policy.dart';
import '../models/ws_discovery_device.dart';
import 'ws_discovery_parser.dart';

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

  static final InternetAddress _multicastAddress = InternetAddress(
    '239.255.255.250',
  );
  static const int _multicastPort = 3702;

  final StreamController<WsDiscoveryEngineEvent> _controller =
      StreamController<WsDiscoveryEngineEvent>.broadcast();
  final List<RawDatagramSocket> _sockets = <RawDatagramSocket>[];
  final List<StreamSubscription<RawSocketEvent>> _subscriptions =
      <StreamSubscription<RawSocketEvent>>[];
  final Map<String, _WsDiscoveryRecord> _records =
      <String, _WsDiscoveryRecord>{};

  Set<String> _types = const <String>{};
  MetadataSecurityPolicy _securityPolicy = MetadataSecurityPolicy.defaultPolicy;
  Timer? _searchTimer;
  Timer? _expiryTimer;
  bool _started = false;
  bool _paused = false;
  bool _stopped = false;

  int _rawObservationCount = 0;
  int _wsDiscoveryFailureCount = 0;

  Stream<WsDiscoveryEngineEvent> get events => _controller.stream;
  int get rawObservationCount => _rawObservationCount;
  int get wsDiscoveryFailureCount => _wsDiscoveryFailureCount;

  Future<void> start({
    required Set<String> wsDiscoveryTypes,
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
    _securityPolicy = metadataSecurityPolicy;
    _types = wsDiscoveryTypes;

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
          _warn(
            'Could not bind WS-Discovery on ${interface.name}: ${error.message}',
          );
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
          // Virtual interfaces might fail to join multicast
        }
      }
      if (!joined) {
        socket.joinMulticast(_multicastAddress);
      }
      _attachSocket(socket);
    } on Object catch (error) {
      _warn(
        'Passive WS-Discovery notifications are unavailable; active search '
        'remains enabled ($error)',
      );
    }
  }

  void _attachSocket(RawDatagramSocket socket) {
    socket
      ..multicastHops = 1
      ..readEventsEnabled = true;
    _sockets.add(socket);
    _subscriptions.add(
      socket.listen(
        (event) {
          if (event != RawSocketEvent.read || _paused || _stopped) return;
          Datagram? datagram;
          while ((datagram = socket.receive()) != null) {
            _handleDatagram(datagram!);
          }
        },
        onError: (Object error) {
          _wsDiscoveryFailureCount++;
          _warn('WS-Discovery socket error: $error');
        },
      ),
    );
  }

  void _sendSearches() {
    if (_paused || _stopped) return;
    final payload = utf8.encode(_buildProbePayload(_types));
    for (final socket in _sockets) {
      if (socket.port == _multicastPort) continue;
      try {
        socket.send(payload, _multicastAddress, _multicastPort);
      } on Object catch (error) {
        _warn('Could not send WS-Discovery search: $error');
      }
    }
  }

  void _handleDatagram(Datagram datagram) {
    _rawObservationCount++;
    try {
      final xmlString = utf8.decode(datagram.data);
      final devices = const WsDiscoveryParser().parse(
        xmlString,
        sourceAddress: datagram.address.address,
        policy: _securityPolicy,
      );
      final now = DateTime.now();
      for (final device in devices) {
        final key = device.endpointReference;
        final existing = _records[key];

        // 60-second default expiry for WS-Discovery observations
        _records[key] = _WsDiscoveryRecord(
          device: device,
          expiresAt: now.add(const Duration(seconds: 60)),
        );

        final isUpdate = existing != null;
        final changed = existing == null ||
            existing.device.types.join(' ') != device.types.join(' ') ||
            existing.device.scopes.join(' ') != device.scopes.join(' ') ||
            existing.device.xAddrs.join(' ') != device.xAddrs.join(' ');

        if (changed) {
          _controller.add(
            WsDiscoveryDeviceDiscovered(device, isUpdate: isUpdate),
          );
        }
      }
    } on Object catch (error) {
      _wsDiscoveryFailureCount++;
      _warn('WS-Discovery parse failed: $error');
    }
  }

  void _expireRecords() {
    if (_paused || _stopped) return;
    final now = DateTime.now();
    _records.removeWhere((key, record) {
      if (record.expiresAt.isBefore(now)) {
        _controller.add(WsDiscoveryDeviceExpired(key));
        return true;
      }
      return false;
    });
  }

  bool _includeInterface(
    String name, {
    required bool includeVpnInterfaces,
    required bool includeCellularInterfaces,
    required bool includePeerToPeer,
  }) {
    final lower = name.toLowerCase();
    if (!includeVpnInterfaces &&
        (lower.contains('vpn') ||
            lower.contains('ppp') ||
            lower.contains('tun') ||
            lower.contains('tap') ||
            lower.contains('p2p'))) {
      return false;
    }
    if (!includeCellularInterfaces &&
        (lower.contains('rmnet') ||
            lower.contains('pdp') ||
            lower.contains('wwan'))) {
      return false;
    }
    if (!includePeerToPeer &&
        (lower.contains('p2p') || lower.contains('wlan-direct'))) {
      return false;
    }
    return true;
  }

  String _buildProbePayload(Set<String> types) {
    final uuid = _generateUuid();
    final typesSection = types.isEmpty
        ? '<wsd:Types xmlns:wsd="http://schemas.xmlsoap.org/ws/2005/04/discovery"/>'
        : '<wsd:Types xmlns:wsd="http://schemas.xmlsoap.org/ws/2005/04/discovery">${types.join(" ")}</wsd:Types>';
    return '<?xml version="1.0" encoding="utf-8"?>'
        '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" '
        'xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" '
        'xmlns:wsd="http://schemas.xmlsoap.org/ws/2005/04/discovery">'
        '<soap:Header>'
        '<wsa:To>urn:schemas-xmlsoap-org:concept:discovery:2005:04</wsa:To>'
        '<wsa:Action>http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</wsa:Action>'
        '<wsa:MessageID>urn:uuid:$uuid</wsa:MessageID>'
        '</soap:Header>'
        '<soap:Body>'
        '<wsd:Probe>'
        '$typesSection'
        '</wsd:Probe>'
        '</soap:Body>'
        '</soap:Envelope>';
  }

  String _generateUuid() {
    final random = math.Random();
    String hexDigit(int value) => value.toRadixString(16);
    final buffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      final b = random.nextInt(256);
      if (i == 6) {
        buffer.write(hexDigit((b & 0x0f) | 0x40).padLeft(2, '0'));
      } else if (i == 8) {
        buffer.write(hexDigit((b & 0x3f) | 0x80).padLeft(2, '0'));
      } else {
        buffer.write(hexDigit(b).padLeft(2, '0'));
      }
    }
    return buffer.toString();
  }

  void _warn(String message) {
    if (!_controller.isClosed) {
      _controller.add(WsDiscoveryEngineWarning(message));
    }
  }

  Future<void> pause() async {
    _paused = true;
  }

  Future<void> resume() async {
    _paused = false;
  }

  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;
    _searchTimer?.cancel();
    _expiryTimer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    for (final socket in _sockets) {
      socket.close();
    }
    _sockets.clear();
    await _controller.close();
  }
}

class _WsDiscoveryRecord {
  const _WsDiscoveryRecord({
    required this.device,
    required this.expiresAt,
  });

  final WsDiscoveryDevice device;
  final DateTime expiresAt;
}
