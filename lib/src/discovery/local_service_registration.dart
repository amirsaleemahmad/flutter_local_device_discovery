import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_local_device_discovery_platform_interface/flutter_local_device_discovery_platform_interface.dart';

/// Request details to register a service on the local network.
class LocalServiceRegistration {
  const LocalServiceRegistration({
    required this.instanceName,
    required this.serviceType,
    required this.port,
    this.txtRecords = const <String, String>{},
    this.host,
    this.interfaceNames = const <String>[],
  });

  final String instanceName;
  final String serviceType;
  final int port;
  final Map<String, String> txtRecords;
  final String? host;
  final List<String> interfaceNames;

  /// Converts this request to the platform interface representation.
  NativeServiceRegistration toNative() {
    return NativeServiceRegistration(
      instanceName: instanceName,
      serviceType: serviceType,
      port: port,
      txtRecords: txtRecords.map(
        (key, value) => MapEntry<String, Uint8List>(
          key,
          Uint8List.fromList(utf8.encode(value)),
        ),
      ),
      host: host,
      interfaceNames: interfaceNames,
    );
  }
}

/// The result handle of a successfully registered service.
class LocalServiceRegistrationResult {
  LocalServiceRegistrationResult({
    required this.registrationId,
    required this.assignedName,
    required this.serviceType,
    required this.port,
    required FlutterLocalDeviceDiscoveryPlatform platform,
  }) : _platform = platform;

  final String registrationId;
  final String assignedName;
  final String serviceType;
  final int port;
  final FlutterLocalDeviceDiscoveryPlatform _platform;

  /// Updates the TXT records of the registered service.
  Future<void> updateTxtRecords(Map<String, String> txtRecords) async {
    final rawTxt = txtRecords.map(
      (key, value) => MapEntry<String, Uint8List>(
        key,
        Uint8List.fromList(utf8.encode(value)),
      ),
    );
    await _platform.updateRegisteredService(registrationId, rawTxt);
  }

  /// Stops advertising and unregisters the service.
  Future<void> stop() async {
    await _platform.unregisterService(registrationId);
  }
}
