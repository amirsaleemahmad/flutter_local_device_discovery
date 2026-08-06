# flutter_local_device_discovery

Native local-network device and service discovery for Flutter using mDNS, DNS-SD, Bonjour, SSDP, UPnP and WS-Discovery across Android, iOS, macOS and Windows.

[![Support on Ko-fi](https://img.shields.io/badge/Support%20me-Ko--fi-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/X8Y824GXT3)


## Features

- **Native-first**: Uses the most appropriate native networking APIs on each platform
- **mDNS/DNS-SD/Bonjour**: Service browsing and resolution
- **Device models**: Normalized, strongly typed device and service models
- **Continuous & snapshot modes**: Both live monitoring and bounded discovery
- **Network-interface awareness**: IPv4/IPv6, Wi-Fi/Ethernet/VPN interfaces
- **Deduplication**: Basic device deduplication across protocols
- **Classification**: Basic device type classification
- **Service-type validation**: Validate and parse service types
- **Address parsing**: Parse and classify IPv4/IPv6 addresses

## Supported Platforms

| Platform | Status |
|----------|--------|
| Android  | ✅ Native NSD |
| iOS      | ✅ Network framework |
| macOS    | ✅ Network framework |
| Windows  | 🚧 Foundation |

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_local_device_discovery: ^0.1.0
```

## Quick Start

### Snapshot Discovery

```dart
import 'package:flutter_local_device_discovery/flutter_local_device_discovery.dart';

final discovery = FlutterLocalDeviceDiscovery();

final result = await discovery.discover(
  const LocalDiscoveryRequest(
    duration: Duration(seconds: 8),
    serviceTypes: {
      '_http._tcp',
      '_ipp._tcp',
      '_printer._tcp',
      '_googlecast._tcp',
    },
  ),
);

for (final device in result.devices) {
  print('${device.displayName}: ${device.addresses}');
}
```

### Continuous Discovery

```dart
final session = await discovery.start(
  const LocalDiscoveryRequest(
    mode: LocalDiscoveryMode.continuous,
    serviceTypes: {'_http._tcp'},
  ),
);

session.events.listen((event) {
  switch (event) {
    case LocalDeviceAdded():
      print('Added: ${event.device.displayName}');
    case LocalDeviceUpdated():
      print('Updated: ${event.device.displayName}');
    case LocalDeviceRemoved():
      print('Removed: ${event.device.displayName}');
    case LocalDiscoveryFailure():
      print(event.error);
  }
});

await session.stop();
```

### Capabilities

```dart
final capabilities = await discovery.getCapabilities();
print(capabilities.supportedProtocols);
```

## Platform Configuration

### Android

Add these permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
```

### iOS

Add to your `Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app discovers devices and services available on your local network.</string>

<key>NSBonjourServices</key>
<array>
    <string>_http._tcp</string>
    <string>_ipp._tcp</string>
</array>
```

Only include service types your application actually uses.

### macOS

Add to your entitlements file:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

### Windows

Multicast traffic may be filtered by the Windows firewall. Public network profiles may behave differently. The plugin does not create firewall exceptions.

## Security & Privacy

- Discovery is not authentication or pairing
- Discovery is not guaranteed inventory
- No response does not always mean offline
- Device classification may be inferred
- MAC addresses may be unavailable
- Multicast may be blocked on guest/enterprise/isolated networks
- No analytics or telemetry is included
- No data is uploaded anywhere

## License

MIT