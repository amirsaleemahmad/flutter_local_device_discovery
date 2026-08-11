import 'package:flutter_local_device_discovery/flutter_local_device_discovery.dart';
import 'package:flutter_local_device_discovery/src/models/ws_discovery_device.dart';
import 'package:flutter_local_device_discovery/src/ws_discovery/ws_discovery_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WS-Discovery XML parsing', () {
    const probeMatchesXml = '''
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" 
               xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" 
               xmlns:wsd="http://schemas.xmlsoap.org/ws/2005/04/discovery"
               xmlns:dn="http://www.onvif.org/ver10/network/wsdl">
  <soap:Header>
    <wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To>
    <wsa:Action>http://schemas.xmlsoap.org/ws/2005/04/discovery/ProbeMatches</wsa:Action>
    <wsa:MessageID>urn:uuid:response-uuid</wsa:MessageID>
    <wsa:RelatesTo>urn:uuid:request-uuid</wsa:RelatesTo>
  </soap:Header>
  <soap:Body>
    <wsd:ProbeMatches>
      <wsd:ProbeMatch>
        <wsa:EndpointReference>
          <wsa:Address>urn:uuid:device-uuid-1234</wsa:Address>
        </wsa:EndpointReference>
        <wsd:Types>dn:NetworkVideoTransmitter</wsd:Types>
        <wsd:Scopes>onvif://www.onvif.org/hardware/CameraModel onvif://www.onvif.org/name/Front_Door</wsd:Scopes>
        <wsd:XAddrs>http://192.168.1.120:80/onvif/device_service</wsd:XAddrs>
        <wsd:MetadataVersion>2</wsd:MetadataVersion>
      </wsd:ProbeMatch>
    </wsd:ProbeMatches>
  </soap:Body>
</soap:Envelope>
''';

    const helloXml = '''
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" 
               xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" 
               xmlns:wsd="http://schemas.xmlsoap.org/ws/2005/04/discovery">
  <soap:Body>
    <wsd:Hello>
      <wsa:EndpointReference>
        <wsa:Address>urn:uuid:hello-device-uuid</wsa:Address>
      </wsa:EndpointReference>
      <wsd:Types>wsd:Device</wsd:Types>
      <wsd:XAddrs>http://192.168.1.130:80</wsd:XAddrs>
    </wsd:Hello>
  </soap:Body>
</soap:Envelope>
''';

    test('parses ProbeMatches correctly', () {
      final parser = const WsDiscoveryParser();
      final results = parser.parse(probeMatchesXml, sourceAddress: '192.168.1.120');

      expect(results, hasLength(1));
      final device = results.first;
      expect(device.endpointReference, 'urn:uuid:device-uuid-1234');
      expect(device.types, contains('dn:NetworkVideoTransmitter'));
      expect(device.scopes, contains('onvif://www.onvif.org/name/Front_Door'));
      expect(device.xAddrs, contains('http://192.168.1.120:80/onvif/device_service'));
      expect(device.metadataVersion, 2);
      expect(device.sourceAddress, '192.168.1.120');
    });

    test('parses Hello notifications correctly', () {
      final parser = const WsDiscoveryParser();
      final results = parser.parse(helloXml, sourceAddress: '192.168.1.130');

      expect(results, hasLength(1));
      final device = results.first;
      expect(device.endpointReference, 'urn:uuid:hello-device-uuid');
      expect(device.types, contains('wsd:Device'));
      expect(device.xAddrs, contains('http://192.168.1.130:80'));
    });

    test('rejects external entities (XXE payload)', () {
      final parser = const WsDiscoveryParser();
      const xxeXml = '''
<!DOCTYPE root [
  <!ENTITY xxe SYSTEM "http://malicious.com/payload">
]>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
  <soap:Body>
    <ProbeMatches>&xxe;</ProbeMatches>
  </soap:Body>
</soap:Envelope>
''';
      expect(() => parser.parse(xxeXml), throwsFormatException);
    });

    test('rejects excessive nesting depth', () {
      final parser = const WsDiscoveryParser();
      const nestedXml = '<root><a><b><c><d><e><f><g><h><i><j><k><l><m><n><o><p>'
          '<EndpointReference><Address>urn:uuid:1</Address></EndpointReference>'
          '</p></o></n></m></l></k></j></i></h></g></f></e></d></c></b></a></root>';
      expect(
        () => parser.parse(
          nestedXml,
          policy: const MetadataSecurityPolicy(maxXmlNestingDepth: 5),
        ),
        throwsFormatException,
      );
    });
  });

  group('DeviceAggregator WS-Discovery & ONVIF integration', () {
    test('merges and classifies ONVIF cameras correctly', () {
      final aggregator = DeviceAggregator();
      final wsDevice = WsDiscoveryDevice(
        endpointReference: 'urn:uuid:front-door-camera',
        types: const ['dn:NetworkVideoTransmitter'],
        scopes: const [
          'onvif://www.onvif.org/hardware/SuperCamera',
          'onvif://www.onvif.org/name/Front_Door_Camera',
        ],
        xAddrs: const ['http://10.0.0.50/onvif/device_service'],
        sourceAddress: '10.0.0.50',
        lastSeenAt: DateTime.now(),
      );

      final merged = aggregator.mergeWsDiscoveryDevice(
        existing: null,
        ws: wsDevice,
        discoveredBy: 'ws-discovery',
      );

      expect(merged.id, 'urn:uuid:front-door-camera');
      expect(merged.displayName, 'Front Door Camera');
      expect(merged.type, LocalDeviceType.camera);
      expect(merged.capabilities, contains(LocalDeviceCapability.onvif));
      expect(
        merged.capabilityEvidence.any((e) => e.capability == 'onvif'),
        isTrue,
      );
    });
  });
}
