# Privacy Policy: `flutter_local_device_discovery`

This document details data handling, permissions, and privacy considerations when using `flutter_local_device_discovery`.

---

## 1. Zero Telemetry Commitment

`flutter_local_device_discovery` does **not** collect, store, or transmit any analytics, crash reports, device identifiers, or telemetry to external servers or cloud providers.

All discovery activities happen purely between the host device and devices located on the same local area network (LAN).

---

## 2. Local Network Usage & Permissions

### 2.1. Apple Platforms (iOS & macOS)
- **Local Network Privacy (iOS 14+)**: When an app invokes discovery, iOS displays a system permission dialog asking the user for access to the Local Network.
- **`Info.plist` Requirements**: Applications must declare `NSLocalNetworkUsageDescription` explaining to users why local network discovery is needed, as well as `NSBonjourServices` listing service types to be browsed.

### 2.2. Android
- **Multicast Lock**: Android requires `CHANGE_WIFI_MULTICAST_STATE` and `ACCESS_WIFI_STATE` to receive UDP multicast packets (SSDP / WS-Discovery).
- **Wi-Fi SSID & BSSID**: On modern Android versions (Android 10+), accessing Wi-Fi network names (SSID/BSSID) requires Location permission (`ACCESS_FINE_LOCATION`).

---

## 3. Data Processing & Isolation

- **In-Memory Processing**: Discovered device data (IPs, TXT records, service endpoints) is processed entirely in volatile memory within the application process.
- **Sanitized Metadata**: The plugin strips and sanitizes unexpected characters from TXT records and validates XML entity safety before returning structured models to your Flutter code.
