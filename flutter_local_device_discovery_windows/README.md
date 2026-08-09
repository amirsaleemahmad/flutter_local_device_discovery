# flutter_local_device_discovery_windows

Windows implementation of [`flutter_local_device_discovery`](https://pub.dev/packages/flutter_local_device_discovery).

This federated package provides the native Windows channel registration and network-interface diagnostics used by the main package. In v0.2.0, SSDP and UPnP are supplied by the main package's shared Dart engine; native Windows DNS-SD is not yet implemented.

Applications should depend on `flutter_local_device_discovery` instead of adding this package directly. It is selected automatically as the Windows implementation.

## Requirements

- A Flutter-supported Windows version
- Flutter 3.24 or later
- Dart 3.5 or later

Windows Firewall and enterprise policy can filter multicast traffic. The plugin does not create firewall exceptions.

## License

MIT. See [LICENSE](LICENSE).
