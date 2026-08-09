# flutter_local_device_discovery v0.2 review app

This example is an interactive review console for the plugin's v0.2 discovery pipeline.

It requires Flutter 3.24 or later and Dart 3.5 or later.

It can exercise:

- Native mDNS/DNS-SD/Bonjour browsing and resolution
- SSDP active searches and passive notifications
- Secure UPnP description fetching and parsing
- Device deduplication across protocols
- Device classification, inferred capabilities, and capability evidence
- Live add/update/remove events
- Readiness checks, warnings, and diagnostics

Run it on a native target:

```bash
flutter pub get
flutter run -d android
flutter run -d ios
flutter run -d macos
flutter run -d windows
```

The browser target intentionally reports discovery as unsupported because web pages cannot open the required multicast sockets.

Apple builds declare the service types shown in the review app through `NSBonjourServices`. Applications should declare only the service types they actually browse. macOS also requires client/server network sandbox entitlements for active searches and passive SSDP notifications.
