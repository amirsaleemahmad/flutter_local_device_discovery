## 2.0.0 - 2026-08-20

### Added

* **Linux Platform Package (`flutter_local_device_discovery_linux`)**: Native D-Bus Avahi desktop client for mDNS/DNS-SD service browsing, resolution, and local service registration on Linux.
* **Native SSDP & WS-Discovery Engines**: Moved SSDP and WS-Discovery discovery engines to native platform implementations on Android (`MulticastSocket` + `MulticastLock`), Darwin (`NWConnectionGroup`), and Windows (Winsock2 `IP_ADD_MEMBERSHIP`), automatically falling back to pure Dart when running in unsupported environments.
* **Wi-Fi & Network Connection Metadata**: Added `getNetworkInfo()` returning `LocalNetworkInfo` (SSID, BSSID, RSSI dBm, signal quality %, frequency band 2.4/5/6 GHz, channel, link speed, gateway, DNS servers, and subnet mask).
* **Network Topology Graph Model**: Added `NetworkTopologyGraph`, `NetworkNode`, `NetworkEdge`, and `TopologyBuilder` (`buildTopology()`) to construct visual and analytical star-topology graphs linking gateway routers, access points, and discovered network nodes with hop-count calculation.
* **Native ICMP Reachability**: Added native ICMP ping support via `probeIcmp()` measuring true round-trip times (RTT) across platforms.
* **Discovery Permissions & Diagnostics**: Added `checkPermissions()` and `requestPermissions()` (`DiscoveryPermissions`) to query local network, location, and Bluetooth authorization.
* **BLE Device Discovery Models**: Added `BleDiscoveryRequest` and `BleDiscoveredDevice` data models and `LocalDiscoveryProtocol.ble` protocol enum value.
* **JSON Serialization**: Added `toJson()` and `fromJson()` across all 15+ models (`LocalDevice`, `LocalService`, `LocalDiscoverySnapshot`, `LocalNetworkInfo`, `NetworkTopologyGraph`, etc.).
* **Expanded OUI Vendor Lookup**: Expanded `OuiVendorResolver` database to over 500+ manufacturer prefixes (ASUS, Netgear, Ubiquiti, Linksys, Cisco, Mikrotik, Dell, Lenovo, Intel, Microsoft/Xbox, Xiaomi, Huawei, LG, Tuya, Shelly, Ring, etc.) and introduced `OuiVendorInfo` with `lookupMacDetailed()`.
* **New IoT & Smart Home Decoders**: Added domain decoders in `IotProtocolDecoders` for Spotify Connect (`_spotify-connect._tcp`), Sonos (`_sonos._tcp`), MQTT Brokers (`_mqtt._tcp`), Home Assistant (`_home-assistant._tcp`), IPP/IPPS printers (`_ipp._tcp`), and DLNA UPnP AV.

### Changed

* Updated all federated package versions to `2.0.0`.
* Cleaned up legacy doc comments across protocol and request models.

## 1.1.0 - 2026-08-16

### Added

* Added offline IEEE OUI manufacturer resolution via `OuiVendorResolver` (resolves MAC addresses into manufacturers like Apple, Espressif, Philips, Samsung, Sony, HP, etc. without internet access).
* Added specialized smart home & IoT protocol decoders via `IotProtocolDecoders` for Matter/Thread (`_matter._tcp`), Apple HomeKit Accessory Protocol (`_hap._tcp`), Google Cast (`_googlecast._tcp`), and Apple AirPlay (`_airplay._tcp`).
* Added `protocolMetadata` and convenience `manufacturer` / `model` / `modelNumber` getters to `LocalDevice`.
* Added pluggable `DiscoveryProtocolAdapter` interface and registry in `FlutterLocalDeviceDiscovery` for third-party custom protocol engines.
* Added `MulticastHealthChecker` and `checkMulticastHealth()` diagnostic helper to detect router multicast drops and IGMP snooping problems.
* Exported `WsDiscoveryDevice` in the root library.
* Added `ARCHITECTURE.md`, `ROADMAP.md`, `PRIVACY.md`, `melos.yaml`, and `.github/` CI workflows and issue templates.
* Updated all federated subpackages to version `1.1.0`.

## 1.0.0 - 2026-08-11

### Added

* Stable, production-ready release.
* Added support for local service registration and peer advertisement across Android, iOS, macOS, and Windows.
* Added `LocalServiceRegistration` and handle result APIs to dynamically register and update TXT records.
* Added native Win32 `DnsServiceRegister`, `DnsServiceRegisterCancel`, and `DnsServiceConstructInstance` integration on Windows.
* Added reachability verification via `ReachabilityProber` featuring safe, concurrent TCP port-proving capabilities.
* Added read-only access to ARP neighbor tables via `NeighborTable` on Android/Linux.
* Updated all federated package version constraints to `1.0.0`.

## 0.3.0 - 2026-08-11

### Added

* Added WS-Discovery (Web Services Dynamic Discovery) engine in pure Dart for cross-platform network device discovery (ONVIF cameras, printers, enterprise equipment).
* Added secure SOAP XML parser for WS-Discovery ProbeMatches, Hello, and Bye messages with XXE protection and nesting-depth limits.
* Added ONVIF profile device classification & capability mapping to `DeviceAggregator` for IP cameras.
* Added native Windows DNS-SD/mDNS browsing and service resolution in C++ using the Win32 `DnsServiceBrowse` and `DnsServiceResolve` APIs.
* Added continuous session presence monitoring with an active grace-period expiry timer in `_LocalDiscoverySessionImpl` for stale devices/services.
* Added WS-Discovery tracking to diagnostics and platform capabilities.
* Updated all federated packages to version `0.3.0`.

## 0.2.0 - 2026-08-09

### Added

* Added active SSDP M-SEARCH across eligible IPv4 interfaces.
* Added passive SSDP alive, update, and byebye processing with cache expiry and continuous rediscovery.
* Added opt-in UPnP device-description fetching with namespaced XML parsing, relative URL resolution, icons, services, and embedded devices.
* Added `MetadataSecurityPolicy` with private-address validation, DNS connection pinning, redirect validation, response-size and timeout limits, and bounded XML parsing.
* Added live cross-protocol aggregation by UDN, hostname, address, and service identity.
* Added device/service classification with `CapabilityEvidence` records.
* Added SSDP and UPnP public models, parsers, and fetcher APIs.
* Added per-session device and service retention limits.

### Changed

* Expanded discovery capabilities and diagnostics to include the shared SSDP/UPnP engine.
* Updated the example application into an interactive v0.2 review console with protocol controls, live events, identity metadata, capability evidence, readiness, and diagnostics.
* Migrated the example Apple projects and Darwin implementation to the current Swift Package Manager layout while retaining a valid plugin-level CocoaPods fallback for older projects.
* Updated the minimum supported SDKs to Dart 3.5 and Flutter 3.24.
* Updated all federated packages to 0.2.0.

### Fixed

* Fixed event leakage between concurrent discovery sessions.
* Fixed Android NSD listeners and multicast locks not being released with their owning session.
* Fixed Apple discovery requiring IPv4 endpoints and removed the broad meta-service browse.
* Fixed web and native diagnostic version reporting for v0.2.0.
* Fixed the Windows event channel fallback so SSDP-only sessions do not fail with `MissingPluginException`.

## 0.1.0 - 2026-08-06

* Initial federated release.
* Added Android NSD and Apple Network framework mDNS/DNS-SD browsing and resolution.
* Added continuous and snapshot discovery sessions.
* Added normalized device, service, address, and network-interface models.
* Added the Windows plugin foundation and native network-interface diagnostics.
* Added service-type validation, basic deduplication, classification, and documentation.
