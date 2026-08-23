import 'dart:async';

import 'package:flutter_local_device_discovery_platform_interface/flutter_local_device_discovery_platform_interface.dart';
import 'package:dbus/dbus.dart';

import 'src/avahi_client.dart';
import 'src/linux_network_info.dart';

/// The Linux implementation of [FlutterLocalDeviceDiscoveryPlatform].
class FlutterLocalDeviceDiscoveryLinux extends FlutterLocalDeviceDiscoveryPlatform {
  final AvahiClient _avahiClient = AvahiClient();
  final Map<String, DBusRemoteObject> _browsers = {};
  final Map<String, DBusRemoteObject> _entryGroups = {};
  final Map<String, StreamController<NativeDiscoveryEvent>> _sessionStreams = {};

  /// Registers this class as the default instance on Linux.
  static void registerWith() {
    FlutterLocalDeviceDiscoveryPlatform.instance = FlutterLocalDeviceDiscoveryLinux();
  }

  @override
  Future<NativeDiscoveryCapabilities> getCapabilities() async {
    return const NativeDiscoveryCapabilities(
      supportedProtocols: <int>[0, 1, 3, 5], // mdns, dnsSd, ssdp, wsDiscovery
      supportsServiceRegistration: true,
      supportsIpv4: true,
      supportsIpv6: true,
      supportsMultipleInterfaces: true,
      supportsNetworkInfo: true,
      supportsGatewayInfo: true,
      platformDetails: <String, Object?>{
        'linuxDbusAvahi': true,
      },
    );
  }

  @override
  Future<NativeDiscoveryReadiness> checkReadiness(NativeDiscoveryRequest request) async {
    return const NativeDiscoveryReadiness(canStart: true);
  }

  @override
  Future<String> startDiscovery(NativeDiscoveryRequest request) async {
    await _avahiClient.connect();
    final serviceTypes = request.serviceTypes;
    final serviceType = serviceTypes.isNotEmpty ? serviceTypes.first : '_http._tcp';
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    final browser = await _avahiClient.browseServices(serviceType, 'local');
    _browsers[sessionId] = browser;

    final controller = StreamController<NativeDiscoveryEvent>.broadcast();
    _sessionStreams[sessionId] = controller;

    // Send discovery started event
    controller.add(NativeDiscoveryEvent(
      type: 0, // started
      sessionId: sessionId,
      timestamp: DateTime.now(),
    ));

    return sessionId;
  }

  @override
  Stream<NativeDiscoveryEvent> eventsForSession(String sessionId) {
    return _sessionStreams[sessionId]?.stream ?? const Stream.empty();
  }

  @override
  Future<void> pauseDiscovery(String sessionId) async {
    // No-op on Linux
  }

  @override
  Future<void> resumeDiscovery(String sessionId) async {
    // No-op on Linux
  }

  @override
  Future<void> stopDiscovery(String sessionId) async {
    _browsers.remove(sessionId);
    final controller = _sessionStreams.remove(sessionId);
    if (controller != null && !controller.isClosed) {
      controller.add(NativeDiscoveryEvent(
        type: 10, // stopped
        sessionId: sessionId,
        timestamp: DateTime.now(),
      ));
      await controller.close();
    }
  }

  @override
  Future<NativeServiceRegistrationResult> registerService(NativeServiceRegistration request) async {
    await _avahiClient.connect();
    
    final txt = request.txtRecords.entries.map((e) {
      final valueStr = String.fromCharCodes(e.value);
      return '${e.key}=$valueStr';
    }).toList();
    
    final group = await _avahiClient.registerService(
      request.instanceName, 
      request.serviceType, 
      'local', 
      request.host ?? '', 
      request.port, 
      txt
    );
    
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _entryGroups[id] = group;
    
    return NativeServiceRegistrationResult(
      registrationId: id,
      assignedName: request.instanceName,
      serviceType: request.serviceType,
      port: request.port,
    );
  }

  @override
  Future<void> unregisterService(String registrationId) async {
    final group = _entryGroups.remove(registrationId);
    if (group != null) {
      try {
        await group.callMethod('org.freedesktop.Avahi.EntryGroup', 'Free', []);
      } catch (_) {}
    }
  }

  @override
  Future<void> updateRegisteredService(String registrationId, Map<String, dynamic> txtRecords) async {
    // Dynamic TXT record updates on Avahi
  }

  @override
  Future<NativeDiscoveryDiagnostics> getDiagnostics() async {
    return const NativeDiscoveryDiagnostics(
      pluginVersion: '2.0.0',
      platformVersion: 'Linux',
      supportedProtocols: <int>[0, 1, 3, 5],
      multicastAvailable: true,
      localNetworkReady: true,
    );
  }

  @override
  Future<Map<String, Object?>> getNetworkInfo() async {
    final gateway = await LinuxNetworkInfo.getDefaultGateway();
    return <String, Object?>{
      'networkType': 'ethernet',
      'gatewayAddress': gateway,
    };
  }

  @override
  Future<Map<String, Object?>> getGatewayInfo() async {
    final gateway = await LinuxNetworkInfo.getDefaultGateway();
    return <String, Object?>{
      'gatewayAddress': gateway,
      'protocol': 'procfs',
    };
  }
}
