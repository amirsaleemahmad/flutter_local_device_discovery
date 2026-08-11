import 'package:flutter_local_device_discovery/flutter_local_device_discovery.dart';
import 'package:flutter_local_device_discovery_platform_interface/flutter_local_device_discovery_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  group('Service Registration', () {
    late _FakePlatform fakePlatform;

    setUp(() {
      fakePlatform = _FakePlatform();
      FlutterLocalDeviceDiscoveryPlatform.instance = fakePlatform;
    });

    test('registers, updates TXT records, and stops successfully', () async {
      final discovery = FlutterLocalDeviceDiscovery();
      const registration = LocalServiceRegistration(
        instanceName: 'Test Service',
        serviceType: '_test._tcp',
        port: 1234,
        txtRecords: {'key1': 'value1'},
      );

      final handle = await discovery.registerService(registration);

      expect(handle.registrationId, 'reg-123');
      expect(handle.assignedName, 'Test Service');
      expect(handle.serviceType, '_test._tcp');
      expect(handle.port, 1234);

      // Verify registration request reached platform
      expect(fakePlatform.registeredRequest, isNotNull);
      expect(fakePlatform.registeredRequest!.instanceName, 'Test Service');
      expect(fakePlatform.registeredRequest!.serviceType, '_test._tcp');
      expect(fakePlatform.registeredRequest!.port, 1234);

      // Update TXT records
      await handle.updateTxtRecords({'key1': 'new-value', 'key2': 'value2'});
      expect(fakePlatform.updatedTxt, isNotNull);
      expect(fakePlatform.updatedTxt!['key1'], isNotNull);
      expect(fakePlatform.updatedTxt!['key2'], isNotNull);

      // Stop registration
      await handle.stop();
      expect(fakePlatform.unregisteredId, 'reg-123');
    });
  });
}

class _FakePlatform extends FlutterLocalDeviceDiscoveryPlatform
    with MockPlatformInterfaceMixin {
  NativeServiceRegistration? registeredRequest;
  Map<String, dynamic>? updatedTxt;
  String? unregisteredId;

  @override
  Future<NativeDiscoveryCapabilities> getCapabilities() async {
    return const NativeDiscoveryCapabilities(supportedProtocols: <int>[0, 1]);
  }

  @override
  Future<NativeDiscoveryReadiness> checkReadiness(
    NativeDiscoveryRequest request,
  ) async {
    return const NativeDiscoveryReadiness(canStart: true);
  }

  @override
  Future<String> startDiscovery(NativeDiscoveryRequest request) async {
    return 'session-1';
  }

  @override
  Stream<NativeDiscoveryEvent> eventsForSession(String sessionId) {
    return const Stream<NativeDiscoveryEvent>.empty();
  }

  @override
  Future<void> pauseDiscovery(String sessionId) async {}

  @override
  Future<void> resumeDiscovery(String sessionId) async {}

  @override
  Future<void> stopDiscovery(String sessionId) async {}

  @override
  Future<NativeDiscoveryDiagnostics> getDiagnostics() async {
    return const NativeDiscoveryDiagnostics(pluginVersion: '0.4.0');
  }

  @override
  Future<NativeServiceRegistrationResult> registerService(
    NativeServiceRegistration request,
  ) async {
    registeredRequest = request;
    return const NativeServiceRegistrationResult(
      registrationId: 'reg-123',
      assignedName: 'Test Service',
      serviceType: '_test._tcp',
      port: 1234,
    );
  }

  @override
  Future<void> updateRegisteredService(
    String registrationId,
    Map<String, dynamic> txtRecords,
  ) async {
    updatedTxt = txtRecords;
  }

  @override
  Future<void> unregisterService(String registrationId) async {
    unregisteredId = registrationId;
  }
}
