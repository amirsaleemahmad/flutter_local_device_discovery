# flutter_local_device_discovery

[![pub package](https://img.shields.io/pub/v/flutter_local_device_discovery.svg)](https://pub.dev/packages/flutter_local_device_discovery)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Support on Ko-fi](https://img.shields.io/badge/Support%20me-Ko--fi-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/X8Y824GXT3)

Discover, resolve, classify, and monitor devices and services on the local network from Flutter. Version 1.1 combines native mDNS/DNS-SD browsing with SSDP, WS-Discovery, offline IEEE OUI manufacturer resolution, specialized smart home decoders (Matter, HomeKit HAP, Google Cast, AirPlay), custom protocol adapters, reachability checks, and multicast health diagnostics.

## Features

- Native Android NSD, Apple Network framework, and Windows DNS-SD service discovery
- mDNS, DNS-SD, and Bonjour browsing, service resolution, and dynamic TXT updates
- Active SSDP M-SEARCH and passive SSDP alive/update/byebye monitoring
- WS-Discovery (SOAP/UDP) targeting ONVIF IP security cameras and enterprise equipment
- Offline IEEE OUI manufacturer resolution for discovered MAC addresses
- Smart home & IoT protocol decoders (Matter/Thread, HomeKit HAP, Google Cast, AirPlay)
- Modular `DiscoveryProtocolAdapter` API for integrating custom discovery engines
- Multicast health diagnostics to detect router multicast drops / IGMP snooping
- Secure, bounded UPnP device-description retrieval with anti-SSRF protections
- Cross-protocol deduplication by UDN, hostname, address, and service identity
- Device classification with inspectable capability evidence

## Platform support

| Platform | Minimum | Discovery support |
| --- | --- | --- |
| Android | API 21 | Native NSD plus SSDP/UPnP and WS-Discovery |
| iOS | 13.0 | Network framework plus SSDP/UPnP and WS-Discovery |
| macOS | 10.15 | Network framework plus SSDP/UPnP and WS-Discovery |
| Windows | Flutter-supported versions | Native DNS-SD/mDNS browsing, resolution, and service registration; SSDP/UPnP and WS-Discovery |
| Web | — | API compiles and reports unsupported; browsers cannot open the required multicast sockets |

The package requires Dart 3.5 or later and Flutter 3.24 or later.

## Installation

Add the package to your application:

```yaml
dependencies:
  flutter_local_device_discovery: ^1.1.0
```

Then run `flutter pub get`.

## Snapshot discovery

`discover` starts a bounded session, waits for the configured duration, returns its normalized snapshot, and releases the session resources.

```dart
import 'package:flutter_local_device_discovery/flutter_local_device_discovery.dart';

final discovery = FlutterLocalDeviceDiscovery();

final snapshot = await discovery.discover(
  const LocalDiscoveryRequest(
    duration: Duration(seconds: 8),
    protocols: {
      LocalDiscoveryProtocol.mdns,
      LocalDiscoveryProtocol.dnsSd,
      LocalDiscoveryProtocol.ssdp,
      LocalDiscoveryProtocol.upnp,
    },
    serviceTypes: {
      '_http._tcp',
      '_ipp._tcp',
      '_googlecast._tcp',
    },
    ssdpSearchTargets: {'ssdp:all'},
    fetchUpnpDescriptions: true,
  ),
);

for (final device in snapshot.devices) {
  print('${device.displayName}: ${device.addresses}');
}
```

UPnP metadata retrieval is opt-in. Set `fetchUpnpDescriptions` to `true` and include either `ssdp` or `upnp` in `protocols`.

## Continuous discovery

Keep the event subscription and session, then cancel and stop both when the owning component is disposed.

```dart
final session = await discovery.start(
  const LocalDiscoveryRequest(
    mode: LocalDiscoveryMode.continuous,
    protocols: {
      LocalDiscoveryProtocol.mdns,
      LocalDiscoveryProtocol.dnsSd,
      LocalDiscoveryProtocol.ssdp,
    },
    serviceTypes: {'_http._tcp'},
    ssdpSearchTargets: {'ssdp:all'},
  ),
);

final subscription = session.events.listen((event) {
  switch (event) {
    case LocalDeviceAdded(:final device):
      print('Added: ${device.displayName}');
    case LocalDeviceUpdated(:final device):
      print('Updated: ${device.displayName}');
    case LocalDeviceRemoved(:final device):
      print('Removed: ${device.displayName}');
    case LocalDiscoveryWarning(:final message):
      print('Warning: $message');
    case LocalDiscoveryFailure(:final error):
      print('Failure: $error');
    case _:
      break;
  }
});

// When discovery is no longer needed:
await subscription.cancel();
await session.stop();
```

Sessions also support `pause()`, `resume()`, and `snapshot()`.

## Capabilities and readiness

Check support before presenting protocol-specific controls, then check whether a concrete request can start:

```dart
final capabilities = await discovery.getCapabilities();
print(capabilities.supportedProtocols);

final request = const LocalDiscoveryRequest(
  protocols: {LocalDiscoveryProtocol.ssdp},
  ssdpSearchTargets: {'ssdp:all'},
);
final readiness = await discovery.checkReadiness(request);

if (!readiness.canStart) {
  print('Requirements: ${readiness.requirements}');
}
```

## Classification evidence and UPnP identity

Classification is an inference from observable service and device metadata. Applications can inspect the supporting evidence instead of treating a classification as authoritative.

```dart
for (final device in snapshot.devices) {
  print('Type: ${device.type}');
  print('UPnP UDN: ${device.identity.upnpUdn}');

  for (final evidence in device.capabilityEvidence) {
    print('${evidence.capability}: ${evidence.source}');
  }
}
```

## Platform configuration

### Android

The Android implementation declares these permissions and they are merged into the consuming application manifest:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
```

### iOS

Add a purpose string and every Bonjour service type your application browses to `ios/Runner/Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app discovers devices and services available on your local network.</string>
<key>NSBonjourServices</key>
<array>
    <string>_http._tcp</string>
    <string>_ipp._tcp</string>
</array>
```

Only declare service types the application actually uses.

### macOS

Add the same `NSLocalNetworkUsageDescription` and `NSBonjourServices` entries to `macos/Runner/Info.plist`. Sandboxed applications also need client and server networking in both debug/profile and release entitlements:

```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
```

#### Enabling Local Network Access (macOS & iOS)

If you encounter `Network.NWError error -65555 - NoAuth` or no devices appear, verify that Local Network permissions are enabled:

**On macOS:**
1. Open **System Settings** ( > System Settings).
2. Click **Privacy & Security** in the sidebar.
3. Scroll down and click **Local Network**.
4. Find **`device_discovery`** (or **`Runner`** / your terminal or IDE if running in debug mode) and toggle the switch to **ON (Enabled)**.
5. Re-open or re-run the app.

**On iOS:**
1. Open the **Settings** app on the iPhone/iPad.
2. Scroll down to **`Device Discovery`** (or **Privacy & Security > Local Network**).
3. Ensure the **Local Network** switch is turned **ON**.

### Windows

Windows Firewall or enterprise policy can filter multicast UDP. Test on the intended network profile; the plugin does not create firewall exceptions.

## UPnP metadata security

UPnP descriptions are untrusted network input. The default `MetadataSecurityPolicy`:

- permits private and link-local targets only
- blocks public and loopback targets
- validates and pins resolved connection addresses
- validates every redirect target
- limits redirects, response size, request time, and XML depth
- rejects XML document types and entity declarations

Relax `allowExternalAddresses` or `allowLoopbackAddresses` only when the application explicitly trusts those targets.

## Important behavior

- Discovery is not authentication, pairing, or a guaranteed network inventory.
- Guest Wi-Fi, client isolation, VPNs, firewalls, and enterprise multicast policy can hide devices.
- A missing response does not prove that a device is offline.
- Service and device metadata can be malformed or intentionally deceptive.
- Neighbor-table inspection, reachability probing, and safe port probing are fully implemented and supported in v1.0.0.

## Example

The included [example application](example/) is a v0.2 review console with protocol controls, live device/service events, UPnP metadata, capability evidence, readiness, and diagnostics.

## Additional documentation

- [Changelog](CHANGELOG.md)
- [Security policy](SECURITY.md)
- [Contributing](CONTRIBUTING.md)
- [API documentation](https://pub.dev/documentation/flutter_local_device_discovery/latest/)

## License

MIT. See [LICENSE](LICENSE).
