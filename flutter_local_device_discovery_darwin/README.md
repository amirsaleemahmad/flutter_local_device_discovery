# flutter_local_device_discovery_darwin

iOS and macOS implementation of [`flutter_local_device_discovery`](https://pub.dev/packages/flutter_local_device_discovery).

This federated package provides Bonjour/mDNS/DNS-SD browsing and resolution through Apple's Network framework. It supports Swift Package Manager and retains a CocoaPods fallback using the same Swift source.

Applications should depend on `flutter_local_device_discovery` instead of adding this package directly. It is selected automatically for iOS and macOS.

## Requirements

- iOS 13.0 or later
- macOS 10.15 or later
- Flutter 3.24 or later
- Dart 3.5 or later

The consuming application must provide its local-network usage description, declared Bonjour service types, and the required macOS sandbox network entitlements. See the [main package documentation](https://pub.dev/packages/flutter_local_device_discovery) for configuration examples.

## License

MIT. See [LICENSE](LICENSE).
