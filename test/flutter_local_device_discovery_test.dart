import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_local_device_discovery/flutter_local_device_discovery.dart';

void main() {
  group('InternetAddressValue', () {
    test('parses valid IPv4 addresses', () {
      final address = InternetAddressValue.parse('192.168.1.1');
      expect(address.isIpv4, isTrue);
      expect(address.isPrivate, isTrue);
      expect(address.isLoopback, isFalse);
    });

    test('parses loopback addresses', () {
      final address = InternetAddressValue.parse('127.0.0.1');
      expect(address.isLoopback, isTrue);
    });

    test('parses link-local addresses', () {
      final address = InternetAddressValue.parse('169.254.1.1');
      expect(address.isLinkLocal, isTrue);
    });

    test('parses IPv6 addresses', () {
      final address = InternetAddressValue.parse('fe80::1');
      expect(address.isIpv6, isTrue);
      expect(address.isLinkLocal, isTrue);
    });

    test('rejects invalid addresses', () {
      expect(InternetAddressValue.tryParse('999.1.1.1'), isNull);
      expect(InternetAddressValue.tryParse(''), isNull);
      expect(InternetAddressValue.tryParse('not-an-ip'), isNull);
    });
  });

  group('ServiceTypeValidator', () {
    test('validates common service types', () {
      expect(ServiceTypeValidator.isValid('_http._tcp'), isTrue);
      expect(ServiceTypeValidator.isValid('_ipp._tcp'), isTrue);
      expect(ServiceTypeValidator.isValid('_airplay._tcp'), isTrue);
      expect(ServiceTypeValidator.isValid('_flutter-device._tcp'), isTrue);
    });

    test('rejects invalid service types', () {
      expect(ServiceTypeValidator.isValid(''), isFalse);
      expect(ServiceTypeValidator.isValid('http'), isFalse);
      expect(ServiceTypeValidator.isValid('_http'), isFalse);
      expect(ServiceTypeValidator.isValid('_http._tcp._inv@lid'), isFalse);
    });

    test('parses service types', () {
      final parts = ServiceTypeValidator.tryParse('_ipp._tcp');
      expect(parts, isNotNull);
      expect(parts!.serviceName, 'ipp');
      expect(parts.transport, 'tcp');
    });
  });

  group('LocalDiscoveryRequest', () {
    test('validates duration', () {
      expect(
        () => const LocalDiscoveryRequest(duration: Duration.zero).validate(),
        throwsArgumentError,
      );
    });

    test('validates service types', () {
      expect(
        () => const LocalDiscoveryRequest(serviceTypes: {'invalid'}).validate(),
        throwsArgumentError,
      );
    });

    test('accepts valid request', () {
      const request = LocalDiscoveryRequest(serviceTypes: {'_http._tcp'});
      expect(() => request.validate(), returnsNormally);
    });

    test('requires a protocol and rejects unsafe SSDP targets', () {
      expect(
        () => const LocalDiscoveryRequest(protocols: {}).validate(),
        throwsArgumentError,
      );
      expect(
        () => const LocalDiscoveryRequest(
          protocols: {LocalDiscoveryProtocol.ssdp},
          ssdpSearchTargets: {'ssdp:all\r\nInjected: value'},
        ).validate(),
        throwsArgumentError,
      );
    });
  });

  group('DeviceFilter', () {
    test('matches by type', () {
      const filter = DeviceFilter(types: {LocalDeviceType.printer});
      final device = LocalDevice(
        id: '1',
        displayName: 'Printer',
        type: LocalDeviceType.printer,
      );
      expect(filter.matches(device), isTrue);
    });

    test('does not match wrong type', () {
      const filter = DeviceFilter(types: {LocalDeviceType.printer});
      final device = LocalDevice(
        id: '1',
        displayName: 'Camera',
        type: LocalDeviceType.camera,
      );
      expect(filter.matches(device), isFalse);
    });
  });

  group('LocalDevice', () {
    test('equality is based on id', () {
      const device1 = LocalDevice(id: '1', displayName: 'Device');
      const device2 = LocalDevice(id: '1', displayName: 'Device');
      const device3 = LocalDevice(id: '2', displayName: 'Device');
      expect(device1, device2);
      expect(device1, isNot(device3));
    });

    test('servicesOfType filters correctly', () {
      final device = LocalDevice(
        id: '1',
        displayName: 'Device',
        services: const [
          LocalService(
            id: 's1',
            instanceName: 'HTTP',
            serviceType: '_http._tcp',
            domain: 'local.',
          ),
          LocalService(
            id: 's2',
            instanceName: 'IPP',
            serviceType: '_ipp._tcp',
            domain: 'local.',
          ),
        ],
      );
      expect(device.servicesOfType('_http._tcp').length, 1);
      expect(device.servicesOfType('_ipp._tcp').length, 1);
      expect(device.servicesOfType('_ssh._tcp').length, 0);
    });
  });

  group('LocalService', () {
    test('txt accessor returns decoded values', () {
      const service = LocalService(
        id: 's1',
        instanceName: 'Test',
        serviceType: '_http._tcp',
        domain: 'local.',
        textTxtRecords: {'path': '/api'},
      );
      expect(service.txt('path'), '/api');
      expect(service.txt('missing'), isNull);
    });
  });
}
