# flutter_local_device_discovery_platform_interface

Platform interface for [`flutter_local_device_discovery`](https://pub.dev/packages/flutter_local_device_discovery).

The package defines the method-channel contract and serializable native models used by the Android, Darwin, and Windows implementations. App developers should depend on the main package rather than this package directly.

Platform implementers should extend `FlutterLocalDeviceDiscoveryPlatform` and use `PlatformInterface.verifyToken` through the provided instance setter.

## Requirements

- Flutter 3.24 or later
- Dart 3.5 or later

## License

MIT. See [LICENSE](LICENSE).
