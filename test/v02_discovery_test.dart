import 'dart:async';
import 'dart:io';

import 'package:flutter_local_device_discovery/flutter_local_device_discovery.dart';
import 'package:flutter_local_device_discovery_platform_interface/flutter_local_device_discovery_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  group('SSDP wire parsing', () {
    test('parses M-SEARCH responses case-insensitively', () {
      final message = SsdpMessageParser.tryParse(
        'HTTP/1.1 200 OK\r\n'
        'CACHE-CONTROL: max-age=1800\r\n'
        'LOCATION: http://192.168.1.20:1400/xml/device.xml\r\n'
        'SERVER: Linux/5 UPnP/1.1 Product/1\r\n'
        'ST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n'
        'USN: uuid:device-1::urn:schemas-upnp-org:device:MediaRenderer:1\r\n'
        'BOOTID.UPNP.ORG: 4\r\n\r\n',
      );

      expect(message, isNotNull);
      expect(message!.kind, SsdpMessageKind.searchResponse);
      expect(message.deviceKey, 'uuid:device-1');
      expect(message.cacheControlMaxAge, 1800);
      final device = message.toDevice(sourceAddress: '192.168.1.20');
      expect(device, isNotNull);
      expect(device!.sourceAddress, '192.168.1.20');
      expect(device.bootId, '4');
    });

    test('parses byebye notifications without requiring LOCATION', () {
      final message = SsdpMessageParser.tryParse(
        'NOTIFY * HTTP/1.1\r\n'
        'HOST: 239.255.255.250:1900\r\n'
        'NT: upnp:rootdevice\r\n'
        'NTS: ssdp:byebye\r\n'
        'USN: uuid:device-1::upnp:rootdevice\r\n\r\n',
      );

      expect(message?.kind, SsdpMessageKind.byebye);
      expect(message?.deviceKey, 'uuid:device-1');
      expect(message?.toDevice(), isNull);
    });

    test('rejects unrelated datagrams and header injection shapes', () {
      expect(SsdpMessageParser.tryParse('hello'), isNull);
      expect(
        SsdpMessageParser.tryParse(
          'HTTP/1.1 200 OK\r\nLOCATION: invalid\r\nUSN: uuid:1\r\n\r\n',
        )?.toDevice(),
        isNull,
      );
    });
  });

  group('UPnP description parsing', () {
    const xml = '''
<?xml version="1.0"?>
<root xmlns="urn:schemas-upnp-org:device-1-0">
  <URLBase>http://192.168.1.20:1400/</URLBase>
  <device>
    <deviceType>urn:schemas-upnp-org:device:MediaRenderer:1</deviceType>
    <friendlyName>Living Room Player</friendlyName>
    <manufacturer>Acme</manufacturer>
    <modelName>Model X</modelName>
    <serialNumber>ABC123</serialNumber>
    <UDN>uuid:device-1</UDN>
    <iconList>
      <icon>
        <mimetype>image/png</mimetype><width>64</width><height>64</height>
        <depth>24</depth><url>/icons/device.png</url>
      </icon>
    </iconList>
    <serviceList>
      <service>
        <serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>
        <serviceId>urn:upnp-org:serviceId:AVTransport</serviceId>
        <SCPDURL>/xml/avtransport.xml</SCPDURL>
        <controlURL>/MediaRenderer/AVTransport/Control</controlURL>
        <eventSubURL>/MediaRenderer/AVTransport/Event</eventSubURL>
      </service>
    </serviceList>
    <deviceList>
      <device>
        <deviceType>urn:schemas-upnp-org:device:MediaRenderer:1</deviceType>
        <friendlyName>Embedded Zone</friendlyName>
        <UDN>uuid:device-1-zone</UDN>
      </device>
    </deviceList>
  </device>
</root>
''';

    test('parses namespaced models, services, icons, and embedded devices', () {
      final description = const UpnpDescriptionParser().parse(
        xml,
        documentUri: Uri.parse('http://192.168.1.20/device.xml'),
      );

      expect(description.udn, 'uuid:device-1');
      expect(description.friendlyName, 'Living Room Player');
      expect(description.services.single.serviceId, contains('AVTransport'));
      expect(
        description.services.single.controlUrl,
        'http://192.168.1.20:1400/MediaRenderer/AVTransport/Control',
      );
      expect(
        description.icons.single.url,
        'http://192.168.1.20:1400/icons/device.png',
      );
      expect(description.embeddedDevices.single.udn, 'uuid:device-1-zone');
    });

    test('rejects entity declarations and excessive nesting', () {
      expect(
        () => const UpnpDescriptionParser().parse(
          '<!DOCTYPE root [<!ENTITY x "value">]><root><device>'
          '<UDN>uuid:1</UDN></device></root>',
        ),
        throwsFormatException,
      );
      expect(
        () => const UpnpDescriptionParser().parse(
          '<root><device><UDN>uuid:1</UDN></device></root>',
          policy: const MetadataSecurityPolicy(maxXmlNestingDepth: 2),
        ),
        throwsFormatException,
      );
    });
  });

  group('UPnP metadata security', () {
    test('blocks public and loopback targets before connecting', () async {
      const fetcher = UpnpDescriptionFetcher();
      await expectLater(
        fetcher.fetch(Uri.parse('http://203.0.113.10/device.xml')),
        throwsA(isA<HttpException>()),
      );
      await expectLater(
        fetcher.fetch(Uri.parse('http://127.0.0.1/device.xml')),
        throwsA(isA<HttpException>()),
      );
    });

    test(
      'fetches, redirects, and parses an explicitly allowed local target',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        server.listen((request) async {
          if (request.uri.path == '/redirect') {
            request.response
              ..statusCode = HttpStatus.found
              ..headers.set(HttpHeaders.locationHeader, '/device.xml');
          } else {
            request.response
              ..headers.contentType = ContentType(
                'application',
                'xml',
                charset: 'utf-8',
              )
              ..write(
                '<root><device><deviceType>urn:test:device:1</deviceType>'
                '<friendlyName>Local Fixture</friendlyName>'
                '<UDN>uuid:local-fixture</UDN></device></root>',
              );
          }
          await request.response.close();
        });

        try {
          final description = await const UpnpDescriptionFetcher().fetch(
            Uri.parse('http://127.0.0.1:${server.port}/redirect'),
            policy: const MetadataSecurityPolicy(
              allowLoopbackAddresses: true,
              timeoutDuration: Duration(seconds: 2),
            ),
          );
          expect(description.udn, 'uuid:local-fixture');
          expect(description.friendlyName, 'Local Fixture');
        } finally {
          await server.close(force: true);
        }
      },
    );
  });

  group('v0.2 session integration', () {
    late _FakePlatform fake;

    setUp(() {
      fake = _FakePlatform();
      FlutterLocalDeviceDiscoveryPlatform.instance = fake;
    });

    tearDown(() async {
      await fake.close();
    });

    test('deduplicates native observations and classifies services', () async {
      final discovery = FlutterLocalDeviceDiscovery();
      final future = discovery.discover(
        const LocalDiscoveryRequest(
          duration: Duration(milliseconds: 80),
          mode: LocalDiscoveryMode.servicesAndDevices,
          protocols: <LocalDiscoveryProtocol>{LocalDiscoveryProtocol.mdns},
          serviceTypes: <String>{'_ipp._tcp'},
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final address = const NativeInternetAddress(
        address: '192.168.1.40',
        family: 4,
        isPrivate: true,
      );
      final service = NativeService(
        id: 'service-1',
        instanceName: 'Office Printer',
        serviceType: '_ipp._tcp',
        domain: 'local.',
        addresses: <NativeInternetAddress>[address],
        port: 631,
        transport: 0,
        protocols: const <int>[0, 1],
        resolved: true,
      );
      fake.emit(
        NativeDiscoveryEvent(
          type: 1,
          sessionId: 'session-1',
          device: NativeDevice(
            id: 'mdns-printer',
            displayName: 'Office Printer',
            hostname: 'printer.local',
            addresses: <NativeInternetAddress>[address],
            services: <NativeService>[service],
            type: 0,
            protocols: const <int>[0, 1],
          ),
        ),
      );
      fake.emit(
        NativeDiscoveryEvent(
          type: 1,
          sessionId: 'session-1',
          device: NativeDevice(
            id: 'second-observation',
            displayName: 'Printer via another protocol',
            hostname: '192.168.1.40',
            addresses: <NativeInternetAddress>[address],
            type: 0,
            protocols: <int>[3],
          ),
        ),
      );
      fake.emit(
        NativeDiscoveryEvent(type: 4, sessionId: 'session-1', service: service),
      );

      final snapshot = await future;
      expect(snapshot.devices, hasLength(1));
      expect(snapshot.services, hasLength(1));
      expect(snapshot.duration, isNot(Duration.zero));
      final device = snapshot.devices.single;
      expect(device.type, LocalDeviceType.printer);
      expect(device.capabilities, contains(LocalDeviceCapability.printing));
      expect(device.capabilityEvidence, isNotEmpty);
      expect(device.discoveredBy, contains(LocalDiscoveryProtocol.ssdp));
      expect(fake.stoppedSessionId, 'session-1');
    });
  });
}

class _FakePlatform extends FlutterLocalDeviceDiscoveryPlatform
    with MockPlatformInterfaceMixin {
  final StreamController<NativeDiscoveryEvent> _events =
      StreamController<NativeDiscoveryEvent>.broadcast();

  String? stoppedSessionId;

  void emit(NativeDiscoveryEvent event) => _events.add(event);

  Future<void> close() => _events.close();

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
    return _events.stream.where(
      (event) => event.sessionId == null || event.sessionId == sessionId,
    );
  }

  @override
  Future<void> pauseDiscovery(String sessionId) async {}

  @override
  Future<void> resumeDiscovery(String sessionId) async {}

  @override
  Future<void> stopDiscovery(String sessionId) async {
    stoppedSessionId = sessionId;
  }

  @override
  Future<NativeDiscoveryDiagnostics> getDiagnostics() async {
    return const NativeDiscoveryDiagnostics(pluginVersion: '0.2.0');
  }
}
