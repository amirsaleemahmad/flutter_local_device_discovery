import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_device_discovery/flutter_local_device_discovery.dart';

void main() {
  group('SsdpDevice', () {
    test('creates with required fields', () {
      const device = SsdpDevice(
        location: 'http://192.168.1.1:1900/desc.xml',
        usn: 'uuid:1234::upnp:rootdevice',
        searchTarget: 'upnp:rootdevice',
      );
      expect(device.location, 'http://192.168.1.1:1900/desc.xml');
      expect(device.usn, 'uuid:1234::upnp:rootdevice');
      expect(device.searchTarget, 'upnp:rootdevice');
    });

    test('equality is based on usn and location', () {
      const a = SsdpDevice(
        location: 'http://1.1.1.1',
        usn: 'uuid:1',
        searchTarget: 'ssdp:all',
      );
      const b = SsdpDevice(
        location: 'http://1.1.1.1',
        usn: 'uuid:1',
        searchTarget: 'ssdp:all',
      );
      const c = SsdpDevice(
        location: 'http://2.2.2.2',
        usn: 'uuid:2',
        searchTarget: 'ssdp:all',
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('UpnpDeviceDescription', () {
    test('creates with required fields', () {
      const desc = UpnpDeviceDescription(udn: 'uuid:1234');
      expect(desc.udn, 'uuid:1234');
      expect(desc.friendlyName, isNull);
      expect(desc.services, isEmpty);
    });

    test('creates with all fields', () {
      const desc = UpnpDeviceDescription(
        udn: 'uuid:1234',
        friendlyName: 'My Device',
        manufacturer: 'Acme',
        services: [
          UpnpService(
            serviceType: 'urn:schemas-upnp-org:service:RenderingControl:1',
            serviceId: 'urn:upnp-org:serviceId:RenderingControl',
          ),
        ],
      );
      expect(desc.friendlyName, 'My Device');
      expect(desc.services.length, 1);
    });
  });

  group('CapabilityEvidence', () {
    test('creates with required fields', () {
      const evidence = CapabilityEvidence(
        capability: 'mediaPlayback',
        source: 'service:_airplay._tcp',
        confidence: 0.9,
      );
      expect(evidence.capability, 'mediaPlayback');
      expect(evidence.confidence, 0.9);
    });
  });

  group('MetadataSecurityPolicy', () {
    test('default policy has safe values', () {
      const policy = MetadataSecurityPolicy.defaultPolicy;
      expect(policy.maxRedirects, 3);
      expect(policy.allowExternalAddresses, false);
      expect(policy.allowLoopbackAddresses, false);
      expect(policy.disableXmlExternalEntities, true);
    });
  });

  group('DeviceAggregator', () {
    final aggregator = DeviceAggregator();

    test('deduplicates devices by hostname', () {
      final devices = [
        LocalDevice(
          id: '1',
          displayName: 'Device A',
          hostname: 'myhost.local',
          discoveredBy: {LocalDiscoveryProtocol.mdns},
          firstSeenAt: DateTime(2024, 1, 1),
          lastSeenAt: DateTime(2024, 1, 2),
        ),
        LocalDevice(
          id: '2',
          displayName: 'Device A (SSDP)',
          hostname: 'myhost.local',
          discoveredBy: {LocalDiscoveryProtocol.ssdp},
          firstSeenAt: DateTime(2024, 1, 1, 1),
          lastSeenAt: DateTime(2024, 1, 3),
        ),
      ];
      final result = aggregator.aggregate(devices);
      expect(result.length, 1);
      expect(result.first.discoveredBy, contains(LocalDiscoveryProtocol.mdns));
      expect(result.first.discoveredBy, contains(LocalDiscoveryProtocol.ssdp));
    });

    test('merges SSDP device into existing device', () {
      final existing = LocalDevice(
        id: '1',
        displayName: 'My Device',
        hostname: 'myhost.local',
        discoveredBy: {LocalDiscoveryProtocol.mdns},
      );
      const ssdp = SsdpDevice(
        location: 'http://192.168.1.1/desc.xml',
        usn: 'uuid:1234::upnp:rootdevice',
        searchTarget: 'upnp:rootdevice',
        friendlyName: 'My UPnP Device',
      );
      final merged = aggregator.mergeSsdpDevice(
        existing: existing,
        ssdp: ssdp,
        discoveredBy: 'ssdp',
      );
      expect(merged.displayName, 'My UPnP Device');
      expect(merged.metadata['ssdpLocation'], 'http://192.168.1.1/desc.xml');
    });

    test('enriches device with UPnP description', () {
      final device = LocalDevice(
        id: '1',
        displayName: 'Old Name',
        hostname: 'myhost.local',
      );
      const desc = UpnpDeviceDescription(
        udn: 'uuid:1234',
        friendlyName: 'New Friendly Name',
        manufacturer: 'Acme Corp',
        services: [
          UpnpService(
            serviceType: 'urn:schemas-upnp-org:service:RenderingControl:1',
            serviceId: 'urn:upnp-org:serviceId:RenderingControl',
          ),
        ],
      );
      final enriched = aggregator.enrichWithUpnp(
        device: device,
        description: desc,
      );
      expect(enriched.displayName, 'New Friendly Name');
      expect(enriched.metadata['upnpUdn'], 'uuid:1234');
      expect(
        enriched.capabilities,
        contains(LocalDeviceCapability.mediaPlayback),
      );
    });
  });

  group('LocalDevice copyWith', () {
    test('copies with updated fields', () {
      final device = LocalDevice(
        id: '1',
        displayName: 'Original',
        type: LocalDeviceType.unknown,
      );
      final copied = device.copyWith(
        displayName: 'Updated',
        type: LocalDeviceType.smartTv,
      );
      expect(copied.id, '1');
      expect(copied.displayName, 'Updated');
      expect(copied.type, LocalDeviceType.smartTv);
    });
  });
}
