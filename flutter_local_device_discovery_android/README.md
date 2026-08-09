# flutter_local_device_discovery_android

Android implementation of [`flutter_local_device_discovery`](https://pub.dev/packages/flutter_local_device_discovery).

This federated package provides native Android NSD browsing, service resolution, session lifecycle management, readiness, and diagnostics. The app-facing package combines it with the shared SSDP/UPnP engine.

Applications should depend on `flutter_local_device_discovery` instead of adding this package directly. It is selected automatically as the Android implementation.

## Requirements

- Android API 21 or later
- Flutter 3.24 or later
- Dart 3.5 or later

The plugin manifest declares the internet, network-state, Wi-Fi-state, and multicast-state permissions required by discovery.

## License

MIT. See [LICENSE](LICENSE).
