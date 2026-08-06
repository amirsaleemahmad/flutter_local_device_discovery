# Master Development Prompt

# `flutter_local_device_discovery`

## Role

Act as a senior Flutter plugin architect, native Android engineer, Apple-platform networking engineer, Windows systems engineer, network-protocol specialist, security engineer, test engineer, and open-source package maintainer.

Build a professional, production-ready, federated Flutter plugin named:

```text
flutter_local_device_discovery
```

The plugin must discover, resolve, classify, monitor, and optionally advertise devices and services available on the user’s local network.

This must not be a Dart-only subnet scanner and must not be a basic wrapper around a single mDNS library.

The plugin must use the most appropriate native networking and service-discovery APIs available on each supported operating system, while presenting one clean, strongly typed, platform-independent Dart API.

The final project must be suitable for publishing on pub.dev as a high-quality community package.

---

# 1. Package Vision

Create a unified native local-device discovery engine for Flutter applications.

The plugin should help Flutter applications discover devices such as:

* Network printers
* IP cameras
* Smart televisions
* Media players
* AirPlay-compatible devices
* Google Cast-compatible devices where discovery information is publicly available
* DLNA and UPnP devices
* NAS devices
* Computers
* Mobile devices advertising services
* IoT devices
* Smart-home hubs
* Home automation bridges
* Routers
* Gateways
* Access points
* Network scanners
* Barcode devices
* POS terminals
* Workshop equipment
* Medical equipment
* Raspberry Pi devices
* Development servers
* Local HTTP APIs
* WebSocket servers
* SSH servers
* FTP and SFTP servers
* SMB-capable devices
* Custom company devices
* Flutter applications advertising custom services

The plugin must provide more than raw host addresses.

It should produce normalized, deduplicated, enriched device models containing as much safely discoverable information as possible.

---

# 2. Core Value Proposition

The package description should communicate this value:

> Discover, resolve, classify, monitor, and advertise devices and services on local networks using native Android, Apple, and Windows APIs with mDNS, DNS-SD, Bonjour, SSDP, UPnP, WS-Discovery, and configurable network probing.

The package must differentiate itself through:

* Multiple discovery protocols
* Native platform implementations
* Unified cross-platform API
* Device and service deduplication
* Device classification
* Device capability inference
* Continuous device-presence monitoring
* Service resolution
* TXT-record parsing
* IPv4 and IPv6 support
* Multiple network-interface support
* Configurable safe probing
* Device fingerprints
* Network change detection
* Permission management
* Discovery diagnostics
* Service advertisement
* Extensible protocol adapters
* Strong privacy and security controls

---

# 3. Name and Package Family

Use the primary package name:

```text
flutter_local_device_discovery
```

Build it as a federated Flutter plugin.

Recommended package structure:

```text
flutter_local_device_discovery/
├── flutter_local_device_discovery/
├── flutter_local_device_discovery_platform_interface/
├── flutter_local_device_discovery_android/
├── flutter_local_device_discovery_darwin/
├── flutter_local_device_discovery_windows/
└── flutter_local_device_discovery_example/
```

The Apple implementation package should use `darwin` when sharing implementation between iOS and macOS.

Optional future packages may include:

```text
flutter_local_device_discovery_linux
flutter_local_device_discovery_web
```

Do not claim support for Linux or web until reliable implementations and tests exist.

---

# 4. Initial Platform Support

Version 1.0 should target:

* Android
* iOS
* macOS
* Windows

Use:

* Kotlin for Android
* Swift for iOS and macOS
* C++/WinRT or modern C++ for Windows
* Dart for the public API and shared models

Avoid Java, Objective-C, or C where modern platform APIs can be accessed cleanly through Kotlin, Swift, and C++.

Using Objective-C++, Win32 C APIs, or native libraries is acceptable when technically necessary.

---

# 5. Native-First Requirement

The plugin must prioritize native functionality.

Do not implement every protocol in Dart merely to claim cross-platform consistency.

Use the native operating system’s discovery, networking, interface-monitoring, and permission mechanisms wherever possible.

Dart must be responsible for:

* Public API
* Cross-platform models
* Configuration
* Event normalization
* High-level deduplication policies
* User-facing builders and helpers
* Shared validation
* Shared serialization
* Testing utilities

Native layers must be responsible for:

* Native service discovery
* Socket and multicast lifecycle where required
* Network-interface monitoring
* Permission-triggering workflows
* Protocol implementation where native APIs exist
* Low-level packet processing
* Background and lifecycle handling
* Platform-specific error mapping
* Efficient event streaming
* Native resource cleanup

---

# 6. Discovery Protocols

Support the following protocols through modular discovery engines.

## 6.1 mDNS

Support multicast DNS discovery.

Requirements:

* IPv4 mDNS
* IPv6 mDNS where supported
* Service browsing
* Hostname resolution
* Address resolution
* TTL handling
* Added, updated, and removed events
* TXT-record extraction
* Interface information
* Duplicate-response handling
* Service-instance normalization

Common multicast targets include:

```text
224.0.0.251:5353
ff02::fb:5353
```

Do not hardcode networking assumptions without platform validation.

---

## 6.2 DNS-SD

Support DNS-Based Service Discovery.

Allow discovery by service type, including:

```text
_http._tcp
_https._tcp
_ipp._tcp
_ipps._tcp
_printer._tcp
_pdl-datastream._tcp
_scanner._tcp
_ssh._tcp
_sftp-ssh._tcp
_ftp._tcp
_smb._tcp
_device-info._tcp
_workstation._tcp
_airplay._tcp
_raop._tcp
_googlecast._tcp
_homekit._tcp
_hap._tcp
_mqtt._tcp
_ws._tcp
_wss._tcp
_websocket._tcp
_flutter-device._tcp
```

Do not assume every service type is available or allowed on every platform.

Developers must be able to provide custom service types.

Validate service-type formatting.

---

## 6.3 Bonjour

Use Bonjour-compatible native discovery on Apple platforms.

Support:

* Service browsing
* Service resolution
* TXT records
* Domain selection
* Include and exclude peer-to-peer interfaces where supported
* Network interface changes
* Service removal
* Service advertisement
* Modern Apple Network framework APIs
* Local Network privacy requirements

Avoid deprecated Apple APIs unless required for a supported OS version and clearly isolated behind availability checks.

---

## 6.4 SSDP

Support Simple Service Discovery Protocol.

Requirements:

* Send configurable `M-SEARCH` requests
* Listen for SSDP responses
* Parse headers case-insensitively
* Support common search targets
* Respect maximum wait duration
* Deduplicate repeated responses
* Validate response origin
* Support IPv4 multicast
* Support IPv6 where practical
* Parse `LOCATION`
* Parse `USN`
* Parse `ST`
* Parse `SERVER`
* Parse cache-control max age
* Parse boot and configuration identifiers where available
* Detect alive and byebye notifications where supported

Common search targets should include:

```text
ssdp:all
upnp:rootdevice
urn:schemas-upnp-org:device:MediaRenderer:1
urn:schemas-upnp-org:device:MediaServer:1
urn:schemas-upnp-org:device:InternetGatewayDevice:1
```

Developers must be able to specify custom targets.

---

## 6.5 UPnP Device Description

When an SSDP result contains a valid description URL, optionally fetch and parse its UPnP device-description document.

Extract when available:

* Friendly name
* Manufacturer
* Manufacturer URL
* Model description
* Model name
* Model number
* Model URL
* Serial number
* UDN
* Device type
* Presentation URL
* Icon metadata
* Embedded devices
* Available services
* Service type
* Service ID
* Control URL
* Event subscription URL
* Service description URL

Network fetching must be:

* Optional
* Time-limited
* Size-limited
* Redirect-limited
* Restricted to safe local-network targets by default
* Protected against XML entity attacks
* Protected against malformed or excessively nested XML
* Cancellable

Do not execute any discovered service action automatically.

---

## 6.6 WS-Discovery

Support WS-Discovery for compatible network devices.

Common use cases include:

* ONVIF cameras
* Network printers
* Scanners
* Windows-compatible network devices
* Enterprise equipment

Requirements:

* Probe messages
* Probe-match parsing
* Endpoint references
* Type parsing
* Scope parsing
* XAddr extraction
* Metadata version
* IPv4 multicast support
* IPv6 where practical
* Configurable probe types and scopes
* Deduplication
* Timeouts
* Cancellation

Implement XML parsing securely.

Do not allow external entity resolution.

---

## 6.7 Configurable Host Discovery

Provide an optional host-discovery engine.

This must be disabled by default unless the developer explicitly enables it.

Possible mechanisms:

* ARP or neighbor-cache inspection where permitted
* ICMP reachability where permitted
* TCP connect probes
* Known-port probes
* Address-range enumeration
* Operating-system neighbor APIs
* Route and subnet information
* Cached device information

Do not require privileged access.

Do not claim that all hosts can be discovered.

Many devices ignore ICMP and closed-port probes, so results must be described as best effort.

---

## 6.8 Safe Port Probing

Allow opt-in probing of a small configurable port list.

Suggested common ports:

```text
22
53
80
443
445
515
548
554
631
1883
1900
5353
8008
8009
8080
8443
8883
9100
```

Requirements:

* Disabled by default
* Small concurrency limit
* Per-host timeout
* Global timeout
* Cancellation
* No banner exploitation
* No authentication attempts
* No credential guessing
* No vulnerability scanning
* No aggressive full-port scanning
* No automatic internet-range scanning
* Restrict to local/private/link-local addresses by default

Provide a clear API name such as:

```dart
SafePortProbeConfig
```

Do not market this as a security scanner.

---

# 7. Platform-Specific Native Implementation

## 7.1 Android

Use Android native networking APIs.

Primary native technologies may include:

```text
android.net.nsd.NsdManager
android.net.ConnectivityManager
android.net.Network
android.net.NetworkCapabilities
android.net.LinkProperties
android.net.wifi.WifiManager
android.net.wifi.MulticastLock
NetworkCallback
DatagramSocket or DatagramChannel
Kotlin coroutines
Flow
```

### Android NSD requirements

Support:

* Discovery start and stop
* Multiple discovery sessions
* Service found
* Service lost
* Service resolution
* Resolve failures
* Registration
* Unregistration
* Network-specific discovery where supported
* Executor-based callbacks on supported API levels
* Compatibility paths for older supported Android versions

Use availability checks rather than assuming every overload exists.

### Android multicast requirements

Manage `WifiManager.MulticastLock` safely where needed.

Rules:

* Acquire only when a discovery engine requires multicast
* Use reference counting carefully
* Release on stop, failure, detach, or engine destruction
* Never leak the multicast lock
* Do not keep the lock indefinitely
* Document battery implications

### Android permissions

Handle and document applicable permissions based on SDK level and feature usage.

Potential permissions may include:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
```

Only add additional permissions when genuinely required.

Do not request location permission merely out of habit.

Support modern Android nearby-network and local-network permission behavior through availability checks when platform requirements evolve.

### Android lifecycle

Handle:

* Activity detach and reattach
* Engine detach
* Hot restart
* App pause and resume
* Network handover
* Wi-Fi disconnect
* Ethernet changes
* VPN activation
* Multiple active networks
* Discovery cancellation

Do not keep stale native callbacks after the Flutter engine is destroyed.

---

## 7.2 iOS

Use modern Apple networking APIs.

Preferred technologies:

```text
Network.framework
NWBrowser
NWEndpoint
NWConnection
NWPathMonitor
NetService only where required for compatibility
Swift concurrency
AsyncStream where appropriate
```

### iOS discovery requirements

Support:

* Bonjour service browsing
* Service result changes
* Service resolution
* Endpoint metadata
* TXT records
* IPv4 and IPv6 endpoints
* Wi-Fi and eligible peer-to-peer discovery where configured
* Network-path changes
* Cancellation
* Service advertisement

### Local Network privacy

Provide professional handling of Apple Local Network privacy.

Requirements:

* Document `NSLocalNetworkUsageDescription`
* Document `NSBonjourServices`
* Generate configuration guidance based on requested service types
* Expose permission-related discovery errors
* Explain that Apple does not provide a simple universal permission-status query
* Avoid fake permission states
* Provide a controlled permission-trigger helper
* Do not trigger permission prompts without a developer action
* Do not add undeclared Bonjour services silently

Example application configuration:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app discovers devices and services available on your local network.</string>

<key>NSBonjourServices</key>
<array>
    <string>_http._tcp</string>
    <string>_ipp._tcp</string>
    <string>_flutter-device._tcp</string>
</array>
```

The package documentation must instruct users to include only service types their application actually uses.

### iOS background behavior

Do not promise unrestricted background discovery.

Document the limitations.

Discovery should pause, stop, or transition appropriately based on application lifecycle and platform restrictions.

---

## 7.3 macOS

Use Apple Network framework with macOS-specific capability handling.

Support:

* Bonjour browsing
* Service resolution
* Service advertisement
* SSDP
* WS-Discovery
* Multiple network interfaces
* Ethernet
* Wi-Fi
* VPN interfaces where allowed
* Network-path changes
* Desktop lifecycle
* Sandboxed applications
* Non-sandboxed applications

Document required macOS entitlements where applicable, including outgoing and incoming network connections.

Example entitlements may include:

```xml
<key>com.apple.security.network.client</key>
<true/>

<key>com.apple.security.network.server</key>
<true/>
```

Only require server entitlement for advertisement or inbound-listener functionality.

---

## 7.4 Windows

Use modern Windows and Win32 networking APIs.

Possible native technologies:

```text
Windows.Networking.ServiceDiscovery.Dnssd
DnssdServiceWatcher
DnsServiceBrowse
DnsServiceResolve
Windows.Networking.Connectivity
NetworkInformation
NetworkStatusChanged
Windows.Networking.Sockets
DatagramSocket
StreamSocket
GetAdaptersAddresses
GetIpNetTable2
NotifyIpInterfaceChange
NotifyRouteChange2
WinHTTP or Windows.Web.Http
C++/WinRT
```

Select APIs based on reliability and Windows-version support.

### Windows requirements

Support:

* DNS-SD browsing
* Service resolution
* Service registration where supported
* SSDP discovery
* UPnP metadata
* WS-Discovery
* Network-interface enumeration
* Adapter changes
* IPv4 and IPv6
* Wi-Fi and Ethernet
* VPN awareness
* Public/private network profile awareness where available
* Cancellation
* Resource cleanup
* COM and apartment initialization where required

### Windows firewall

Document that:

* Multicast traffic may be filtered
* Firewall rules may affect discovery
* Public network profiles may behave differently
* Application packaging can affect network capabilities
* The plugin must not silently create firewall exceptions

Provide actionable diagnostic errors instead of failing silently.

---

# 8. Discovery Modes

Provide high-level discovery modes.

```dart
enum LocalDiscoveryMode {
  servicesOnly,
  devicesOnly,
  servicesAndDevices,
  continuous,
  snapshot,
}
```

Definitions:

## `servicesOnly`

Discover advertised services without subnet probing.

## `devicesOnly`

Build device-level results from all enabled engines.

## `servicesAndDevices`

Return both device and service streams.

## `continuous`

Continue monitoring additions, updates, removals, and network changes.

## `snapshot`

Run for a defined duration and return one deduplicated result.

---

# 9. Protocol Enumeration

Create a public protocol enum:

```dart
enum LocalDiscoveryProtocol {
  mdns,
  dnsSd,
  bonjour,
  ssdp,
  upnp,
  wsDiscovery,
  neighborTable,
  reachability,
  safePortProbe,
}
```

Bonjour and DNS-SD may map to the same underlying technology on some platforms, but preserve useful source information in results.

Avoid exposing implementation-specific protocol names unnecessarily.

---

# 10. Main Public API

Provide a simple primary entry point.

```dart
final discovery = FlutterLocalDeviceDiscovery();
```

Basic snapshot usage:

```dart
final result = await discovery.discover(
  const LocalDiscoveryRequest(
    duration: Duration(seconds: 8),
    protocols: {
      LocalDiscoveryProtocol.mdns,
      LocalDiscoveryProtocol.dnsSd,
      LocalDiscoveryProtocol.ssdp,
      LocalDiscoveryProtocol.wsDiscovery,
    },
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

Continuous monitoring:

```dart
final session = await discovery.start(
  const LocalDiscoveryRequest(
    mode: LocalDiscoveryMode.continuous,
    protocols: {
      LocalDiscoveryProtocol.mdns,
      LocalDiscoveryProtocol.ssdp,
      LocalDiscoveryProtocol.wsDiscovery,
    },
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

The API must support:

* Start
* Stop
* Pause where meaningful
* Resume where meaningful
* Cancel
* Snapshot discovery
* Continuous discovery
* Session IDs
* Multiple independent sessions
* Per-session configuration
* Per-session event streams
* Global diagnostics
* Platform capability checks

---

# 11. Capability API

Provide:

```dart
final capabilities = await discovery.getCapabilities();
```

Model:

```dart
class LocalDiscoveryCapabilities {
  final Set<LocalDiscoveryProtocol> supportedProtocols;
  final bool supportsServiceRegistration;
  final bool supportsIpv4;
  final bool supportsIpv6;
  final bool supportsMultipleInterfaces;
  final bool supportsNetworkSpecificDiscovery;
  final bool supportsNeighborTable;
  final bool supportsReachability;
  final bool supportsSafePortProbe;
  final bool requiresLocalNetworkPermission;
  final bool requiresMulticastPermission;
  final Map<String, Object?> platformDetails;
}
```

Never expose a feature as supported when it is only stubbed.

---

# 12. Discovery Request

Create an immutable configuration model.

```dart
class LocalDiscoveryRequest {
  final LocalDiscoveryMode mode;
  final Set<LocalDiscoveryProtocol> protocols;
  final Set<String> serviceTypes;
  final Set<String> ssdpSearchTargets;
  final Set<String> wsDiscoveryTypes;
  final Duration duration;
  final Duration resolveTimeout;
  final Duration metadataTimeout;
  final Duration lostDeviceGracePeriod;
  final bool resolveServices;
  final bool fetchUpnpDescriptions;
  final bool includeIpv4;
  final bool includeIpv6;
  final bool includeLoopback;
  final bool includeLinkLocal;
  final bool includeVpnInterfaces;
  final bool includeCellularInterfaces;
  final bool includePeerToPeer;
  final bool deduplicateResults;
  final bool classifyDevices;
  final bool monitorNetworkChanges;
  final SafePortProbeConfig? safePortProbe;
  final HostDiscoveryConfig? hostDiscovery;
  final DeviceFilter? filter;
  final Map<String, Object?> metadata;
}
```

Use safe defaults.

Suggested defaults:

* mDNS enabled
* DNS-SD enabled
* SSDP enabled
* WS-Discovery optional
* Host range scanning disabled
* Port probing disabled
* UPnP metadata fetch optional
* IPv4 enabled
* IPv6 enabled where supported
* Loopback excluded
* Cellular excluded
* VPN excluded unless requested
* Deduplication enabled
* Classification enabled
* Short bounded timeouts

---

# 13. Device Model

Create an immutable normalized device model.

```dart
class LocalDevice {
  final String id;
  final String displayName;
  final String? hostname;
  final Set<InternetAddressValue> addresses;
  final Set<LocalNetworkInterface> interfaces;
  final Set<LocalService> services;
  final LocalDeviceType type;
  final Set<LocalDeviceCapability> capabilities;
  final LocalDeviceIdentity identity;
  final LocalDeviceVendor? vendor;
  final LocalDeviceReachability reachability;
  final Set<LocalDiscoveryProtocol> discoveredBy;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final Duration? advertisedTtl;
  final double confidence;
  final Map<String, Object?> metadata;
}
```

Requirements:

* Immutable
* JSON serializable
* Equality support
* Safe `toString`
* No giant binary payloads
* No unbounded raw packet storage
* No personally sensitive values logged by default
* Stable-enough session identity
* Clear distinction between confirmed and inferred fields

---

# 14. Device Identity

Create:

```dart
class LocalDeviceIdentity {
  final String? macAddress;
  final String? serviceInstance;
  final String? uniqueDeviceName;
  final String? upnpUdn;
  final String? wsEndpointReference;
  final String? serialNumber;
  final String? model;
  final String? manufacturer;
  final Map<String, String> identifiers;
}
```

Rules:

* Do not promise MAC-address availability.
* Modern platforms often restrict access to hardware addresses.
* Treat MAC address as optional.
* Do not manufacture fake MAC addresses.
* Do not use randomized or temporary addresses as permanent identity.
* Mark inferred identity values.
* Do not expose stable tracking identifiers unnecessarily.

---

# 15. Device Types

Create an extensible enum or sealed classification model.

Suggested types:

```dart
enum LocalDeviceType {
  unknown,
  computer,
  mobileDevice,
  tablet,
  printer,
  scanner,
  camera,
  smartTv,
  mediaRenderer,
  mediaServer,
  speaker,
  router,
  gateway,
  accessPoint,
  nas,
  storage,
  server,
  webServer,
  developmentServer,
  smartHomeHub,
  homeAutomationBridge,
  sensor,
  actuator,
  posTerminal,
  barcodeScanner,
  weighingScale,
  medicalDevice,
  industrialDevice,
  raspberryPi,
  microcontroller,
  custom,
}
```

Allow custom classifications without forcing a package update.

---

# 16. Device Capabilities

Provide capability inference.

```dart
enum LocalDeviceCapability {
  http,
  https,
  ssh,
  ftp,
  sftp,
  smb,
  printing,
  securePrinting,
  scanning,
  airPlay,
  audioStreaming,
  videoStreaming,
  dlna,
  upnp,
  onvif,
  cast,
  mqtt,
  websocket,
  fileSharing,
  remoteDesktop,
  smartHome,
  customService,
}
```

Each inferred capability should include confidence and evidence.

Example:

```dart
class LocalCapabilityEvidence {
  final LocalDeviceCapability capability;
  final double confidence;
  final Set<String> serviceTypes;
  final Set<int> ports;
  final Set<LocalDiscoveryProtocol> protocols;
  final Map<String, Object?> attributes;
}
```

Do not infer sensitive or security-related capabilities without evidence.

---

# 17. Service Model

Create:

```dart
class LocalService {
  final String id;
  final String instanceName;
  final String serviceType;
  final String domain;
  final String? hostname;
  final Set<InternetAddressValue> addresses;
  final int? port;
  final LocalTransportProtocol transport;
  final Map<String, Uint8List> rawTxtRecords;
  final Map<String, String> textTxtRecords;
  final Set<LocalDiscoveryProtocol> discoveredBy;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final Duration? ttl;
  final bool resolved;
  final Uri? location;
  final Map<String, Object?> metadata;
}
```

TXT-record handling must preserve raw bytes because TXT values are not guaranteed to be valid UTF-8 strings.

Provide convenience decoding without destroying raw data.

---

# 18. Network Interface Model

Create:

```dart
class LocalNetworkInterface {
  final String id;
  final String name;
  final String? displayName;
  final LocalInterfaceType type;
  final Set<InternetAddressValue> addresses;
  final bool isUp;
  final bool isDefault;
  final bool supportsMulticast;
  final bool isMetered;
  final bool isVpn;
  final int? interfaceIndex;
  final Map<String, Object?> platformDetails;
}
```

Interface types:

```dart
enum LocalInterfaceType {
  unknown,
  wifi,
  ethernet,
  vpn,
  cellular,
  loopback,
  peerToPeer,
  virtual,
}
```

Do not assume Wi-Fi is always the active local-network interface.

---

# 19. Internet Address Model

Avoid exposing `dart:io InternetAddress` directly in all serializable models.

Create:

```dart
class InternetAddressValue {
  final String address;
  final InternetAddressFamily family;
  final int? scopeId;
  final String? interfaceName;
  final bool isLoopback;
  final bool isLinkLocal;
  final bool isPrivate;
  final bool isMulticast;
}
```

Validate addresses.

Correctly handle IPv6 zone identifiers and link-local scope.

---

# 20. Device Deduplication

Create a professional deduplication engine.

The same physical device may appear through:

* mDNS
* DNS-SD
* SSDP
* UPnP
* WS-Discovery
* Multiple service types
* IPv4
* IPv6
* Different network interfaces
* Host probing

The plugin must merge compatible observations into one device while preserving source evidence.

Possible deduplication signals:

* Matching UDN
* Matching WS endpoint reference
* Matching service-instance relationships
* Matching hostname
* Matching resolved addresses
* Matching serial number
* Matching manufacturer and model
* Matching unique TXT-record identifiers
* Matching protocol metadata
* Matching known address and port relationships

Do not merge solely because two devices share the same display name.

Provide:

```dart
abstract interface class LocalDeviceDeduplicator {
  DeviceMergeDecision compare(
    LocalDeviceObservation first,
    LocalDeviceObservation second,
  );
}
```

Allow custom deduplicators.

Expose merge confidence and reasons.

---

# 21. Observation Model

Internally represent raw discoveries as observations.

```dart
class LocalDeviceObservation {
  final String observationId;
  final LocalDiscoveryProtocol protocol;
  final String nativeSource;
  final String? name;
  final Set<InternetAddressValue> addresses;
  final LocalService? service;
  final LocalDeviceIdentity partialIdentity;
  final DateTime observedAt;
  final Duration? ttl;
  final Map<String, Object?> attributes;
}
```

Keep protocol parsing separate from device aggregation.

---

# 22. Device Classification Engine

Create a rule-based classifier.

```dart
abstract interface class LocalDeviceClassifier {
  LocalDeviceClassification classify(
    LocalDeviceCandidate candidate,
  );
}
```

Classification evidence may include:

* Service types
* UPnP device types
* WS-Discovery types
* TXT-record keys
* Manufacturer
* Model
* Hostname patterns
* Known public ports
* Protocol combinations
* Device description metadata

Do not base classification on invasive fingerprinting.

Allow developers to add custom rules:

```dart
final discovery = FlutterLocalDeviceDiscovery(
  classifiers: [
    DefaultLocalDeviceClassifier(),
    WorkshopDeviceClassifier(),
  ],
);
```

---

# 23. Device Presence and Lost Detection

Provide reliable event semantics.

Events:

```dart
sealed class LocalDiscoveryEvent {}

class LocalDiscoveryStarted extends LocalDiscoveryEvent {}

class LocalDeviceAdded extends LocalDiscoveryEvent {}

class LocalDeviceUpdated extends LocalDiscoveryEvent {}

class LocalDeviceRemoved extends LocalDiscoveryEvent {}

class LocalServiceAdded extends LocalDiscoveryEvent {}

class LocalServiceUpdated extends LocalDiscoveryEvent {}

class LocalServiceRemoved extends LocalDiscoveryEvent {}

class LocalNetworkChanged extends LocalDiscoveryEvent {}

class LocalDiscoveryWarning extends LocalDiscoveryEvent {}

class LocalDiscoveryFailure extends LocalDiscoveryEvent {}

class LocalDiscoveryStopped extends LocalDiscoveryEvent {}
```

A device should not be removed immediately after one lost-service event when other evidence still indicates it is present.

Use:

* TTL
* Last-seen time
* Protocol-specific removal signals
* Configurable grace period
* Remaining services
* Interface changes
* Reachability evidence

Provide clear event ordering guarantees.

---

# 24. Reachability

Create:

```dart
class LocalDeviceReachability {
  final LocalReachabilityStatus status;
  final DateTime? lastCheckedAt;
  final Duration? latency;
  final String? successfulAddress;
  final int? successfulPort;
  final Set<LocalReachabilityMethod> methods;
}
```

Statuses:

```dart
enum LocalReachabilityStatus {
  unknown,
  reachable,
  partiallyReachable,
  unreachable,
  stale,
}
```

Do not mark a device unreachable merely because ICMP failed.

Reachability checks must be opt-in or minimal.

---

# 25. Service Advertisement

Support local service registration and advertisement where platform APIs permit.

Example:

```dart
final registration = await discovery.registerService(
  const LocalServiceRegistration(
    instanceName: 'Aamir Workshop App',
    serviceType: '_flutter-device._tcp',
    port: 8080,
    txtRecords: {
      'app': 'workshop',
      'version': '1.0',
      'platform': 'flutter',
    },
  ),
);

await registration.updateTxtRecords({
  'status': 'ready',
});

await registration.stop();
```

Requirements:

* Register
* Update metadata where supported
* Unregister
* Handle name conflicts
* Report assigned service name
* Report registration failure
* Stop automatically on engine destruction
* Support multiple registrations where platform allows
* Validate type, name, port, and TXT-record limits
* Preserve raw TXT values
* Do not advertise without an explicit developer call

---

# 26. Custom Flutter Peer Discovery

Provide an optional predefined service type:

```text
_flutter-device._tcp
```

Create helpers for Flutter-to-Flutter peer discovery.

```dart
final peer = await FlutterPeerAdvertisement.start(
  name: 'Reception Tablet',
  port: 8080,
  attributes: {
    'role': 'reception',
    'apiVersion': '2',
  },
);
```

Provide:

* Peer advertisement
* Peer discovery
* Typed metadata
* App protocol version
* Optional public key fingerprint
* Optional one-time pairing token
* Compatibility filtering

Do not implement insecure automatic trust.

Discovery is not authentication.

---

# 27. Permission and Readiness API

Create:

```dart
final readiness = await discovery.checkReadiness(request);
```

Model:

```dart
class LocalDiscoveryReadiness {
  final bool canStart;
  final Set<LocalDiscoveryRequirement> requirements;
  final Set<LocalDiscoveryWarning> warnings;
  final Map<String, Object?> platformDetails;
}
```

Requirements may include:

* Local Network description missing
* Bonjour service type not declared
* Network unavailable
* Multicast unavailable
* Required entitlement missing
* Firewall may block discovery
* Unsupported protocol
* Unsupported address family
* Required Android manifest permission missing

Do not claim to inspect build configuration when runtime APIs cannot prove it.

Use best-effort diagnostics and clear documentation.

---

# 28. Error Model

Create a sealed, strongly typed error hierarchy.

```dart
sealed class LocalDiscoveryException implements Exception {}

class LocalDiscoveryUnsupportedException
    extends LocalDiscoveryException {}

class LocalDiscoveryPermissionException
    extends LocalDiscoveryException {}

class LocalDiscoveryConfigurationException
    extends LocalDiscoveryException {}

class LocalDiscoveryNetworkUnavailableException
    extends LocalDiscoveryException {}

class LocalDiscoveryMulticastException
    extends LocalDiscoveryException {}

class LocalDiscoveryTimeoutException
    extends LocalDiscoveryException {}

class LocalDiscoveryResolutionException
    extends LocalDiscoveryException {}

class LocalDiscoveryProtocolException
    extends LocalDiscoveryException {}

class LocalDiscoveryPlatformException
    extends LocalDiscoveryException {}

class LocalDiscoveryCancelledException
    extends LocalDiscoveryException {}
```

Errors should include:

* Stable error code
* Human-readable message
* Platform
* Protocol
* Session ID
* Recoverability
* Suggested action
* Sanitized native error
* Optional original exception where safe

Never expose raw packet contents, credentials, or private metadata in errors.

---

# 29. Native Error Codes

Normalize native errors.

Example stable codes:

```text
unsupported_protocol
permission_denied
local_network_permission_denied
network_unavailable
multicast_unavailable
invalid_service_type
invalid_configuration
discovery_already_active
discovery_start_failed
discovery_stop_failed
service_resolution_failed
service_registration_failed
service_name_conflict
socket_bind_failed
socket_send_failed
socket_receive_failed
metadata_fetch_failed
metadata_parse_failed
timeout
cancelled
platform_failure
```

Document every public error code.

---

# 30. Session Architecture

Each discovery call must create a session.

```dart
abstract interface class LocalDiscoverySession {
  String get id;

  LocalDiscoveryRequest get request;

  LocalDiscoverySessionState get state;

  Stream<LocalDiscoveryEvent> get events;

  Future<LocalDiscoverySnapshot> snapshot();

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();
}
```

States:

```dart
enum LocalDiscoverySessionState {
  created,
  starting,
  running,
  paused,
  stopping,
  stopped,
  failed,
}
```

Rules:

* Stop must be idempotent.
* Native resources must be released.
* Event streams must close.
* No callbacks after stopped state.
* Multiple sessions must not corrupt each other.
* Shared native resources may be reference counted internally.
* Session IDs must be unique.
* Snapshot state must be immutable.

---

# 31. Concurrency and Resource Management

Handle:

* Multiple protocol engines
* Multiple sessions
* Simultaneous service resolution
* Network changes during resolution
* App lifecycle changes
* Native callback races
* Duplicate stop calls
* Flutter engine detach
* Hot restart
* Timed-out requests
* Cancellation during parsing
* Cancellation during HTTP metadata fetch

Use bounded concurrency.

Do not create one thread per device.

Avoid unbounded event queues.

Apply backpressure, batching, or coalescing where appropriate.

Release:

* Sockets
* Browsers
* Watchers
* Native listeners
* Timers
* Multicast locks
* Network callbacks
* COM objects
* Cancellable tasks
* Event channels

---

# 32. Platform Channel Architecture

Use Pigeon for strongly typed platform communication where practical.

Possible channels:

```text
LocalDiscoveryHostApi
LocalDiscoveryFlutterApi
LocalDiscoverySessionHostApi
LocalServiceRegistrationHostApi
```

Use EventChannel only when it provides clear benefits.

Avoid passing giant nested dynamic maps without schema validation.

Consider native event batching:

```dart
class NativeDiscoveryEventBatch {
  final String sessionId;
  final List<NativeDiscoveryEvent> events;
}
```

Do not send raw network packets to Dart unless a specific debugging API explicitly requests sanitized packet information.

---

# 33. Performance Requirements

The plugin must:

* Avoid blocking the Flutter UI thread
* Avoid blocking Android main thread
* Avoid blocking Apple main actor unnecessarily
* Avoid blocking Windows UI thread
* Use native background queues
* Batch rapid native events
* Bound metadata-fetch concurrency
* Deduplicate repeated advertisements
* Cache resolved services until TTL expiry
* Avoid resolving the same service repeatedly
* Avoid repeated XML fetches
* Avoid scanning inactive interfaces
* Release resources promptly
* Prevent timer and listener leaks
* Remain responsive with hundreds of observations
* Avoid excessive battery consumption

Provide configurable limits:

```dart
class LocalDiscoveryLimits {
  final int maxDevices;
  final int maxServices;
  final int maxConcurrentResolutions;
  final int maxConcurrentMetadataRequests;
  final int maxPendingEvents;
  final int maxTxtRecordBytes;
  final int maxMetadataDocumentBytes;
}
```

---

# 34. Security Requirements

Treat all local-network data as untrusted.

Protect against:

* Malformed DNS packets
* Malformed TXT records
* Oversized packets
* Invalid UTF-8
* XML entity expansion
* External XML entities
* Excessive XML nesting
* Redirect loops
* Metadata response bombs
* Slow responses
* Hostname injection
* Header injection
* Invalid URLs
* SSRF-like metadata fetches
* Internet URL redirection from a local device
* IPv6 parsing mistakes
* Duplicate identifier collisions
* Native memory misuse
* Integer overflows
* Event flooding

UPnP and WS metadata parsing must disable dangerous XML features.

Only fetch metadata from local addresses by default.

Provide:

```dart
enum MetadataNetworkPolicy {
  localOnly,
  sameHostOnly,
  custom,
}
```

Never:

* Attempt default passwords
* Try credentials
* Exploit services
* Perform vulnerability scans
* Open administrative pages automatically
* Execute UPnP actions automatically
* Send control commands without an explicit application action
* Advertise the plugin as a hacking tool

---

# 35. Privacy Requirements

The package must:

* Explain local-network privacy implications
* Avoid persistent device tracking by default
* Avoid uploading discovery information
* Contain no analytics SDK
* Contain no telemetry by default
* Contain no advertisements
* Avoid storing discovered devices automatically
* Allow applications to configure retention
* Avoid exposing stable identifiers unnecessarily
* Provide safe logging
* Redact sensitive values in diagnostics
* Never transmit discovery data to a third party

Provide a privacy section in README.

---

# 36. Logging

Create an optional logger abstraction.

```dart
abstract interface class LocalDiscoveryLogger {
  void trace(String message);
  void debug(String message);
  void warning(String message);
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });
}
```

Default:

```dart
NoOpLocalDiscoveryLogger
```

Never log:

* Entire raw packets
* Authentication tokens
* URLs containing credentials
* Private keys
* Pairing secrets
* Full UPnP metadata without explicit debug opt-in
* Persisted device lists
* Personally identifying custom TXT data

Provide sanitized diagnostics separately.

---

# 37. Filters

Create a strongly typed filter system.

```dart
class DeviceFilter {
  final Set<LocalDeviceType>? types;
  final Set<LocalDeviceCapability>? capabilities;
  final Set<LocalDiscoveryProtocol>? protocols;
  final Set<String>? serviceTypes;
  final Set<String>? hostnames;
  final Set<String>? manufacturers;
  final Set<int>? ports;
  final bool Function(LocalDevice device)? predicate;
}
```

Native filtering should be used where supported.

Dart filtering may be applied after normalization.

Do not serialize arbitrary Dart predicates across platform channels.

---

# 38. Custom Protocol Extensions

Design extension points for future protocols.

```dart
abstract interface class LocalDiscoveryEngine {
  LocalDiscoveryProtocolDescriptor get descriptor;

  Stream<LocalDeviceObservation> discover(
    LocalDiscoveryEngineContext context,
  );

  Future<void> stop();
}
```

Native engines should remain internal unless a stable plugin-extension mechanism is designed.

Provide a public Dart-level custom observation source:

```dart
final discovery = FlutterLocalDeviceDiscovery(
  customObservationSources: [
    CompanyDeviceObservationSource(),
  ],
);
```

Do not expose unstable internal native implementation classes as public API.

---

# 39. Snapshot Result

Create:

```dart
class LocalDiscoverySnapshot {
  final String sessionId;
  final List<LocalDevice> devices;
  final List<LocalService> services;
  final List<LocalNetworkInterface> interfaces;
  final DateTime startedAt;
  final DateTime completedAt;
  final Duration duration;
  final Set<LocalDiscoveryProtocol> completedProtocols;
  final Map<LocalDiscoveryProtocol, ProtocolDiscoverySummary>
      protocolSummaries;
  final List<LocalDiscoveryWarning> warnings;
}
```

Make collections immutable.

Provide JSON serialization for diagnostics and testing.

Do not automatically persist snapshots.

---

# 40. Diagnostics

Provide:

```dart
final diagnostics = await discovery.getDiagnostics();
```

Diagnostics may contain:

* Plugin version
* Platform version
* Supported protocols
* Active sessions
* Network interfaces
* Multicast capability
* Local-network readiness
* Number of raw observations
* Number of deduplicated devices
* Protocol start and stop status
* Resolution success and failure counts
* Metadata-fetch counts
* Dropped event count
* Last network-change time
* Native resource counts
* Sanitized recent warnings

Do not include full TXT records by default.

Provide export:

```dart
final report = diagnostics.toSanitizedJson();
```

---

# 41. Service-Type Catalog

Provide a curated optional catalog.

```dart
abstract final class CommonLocalServiceTypes {
  static const http = '_http._tcp';
  static const https = '_https._tcp';
  static const ipp = '_ipp._tcp';
  static const ipps = '_ipps._tcp';
  static const printer = '_printer._tcp';
  static const ssh = '_ssh._tcp';
  static const smb = '_smb._tcp';
  static const airPlay = '_airplay._tcp';
  static const raop = '_raop._tcp';
  static const googleCast = '_googlecast._tcp';
  static const homeKit = '_hap._tcp';
  static const mqtt = '_mqtt._tcp';
  static const flutterDevice = '_flutter-device._tcp';
}
```

Do not claim ownership or guaranteed behavior of third-party protocols.

Do not include proprietary control implementations in the discovery package.

---

# 42. Utility APIs

Provide safe utility APIs such as:

```dart
LocalServiceType.parse(...)
LocalServiceType.tryParse(...)
InternetAddressValue.parse(...)
LocalAddressClassifier.classify(...)
TxtRecordCodec.decode(...)
TxtRecordCodec.encode(...)
LocalDeviceIdBuilder.build(...)
```

Validation errors must be clear.

Avoid overly permissive parsing.

---

# 43. Package Architecture

Suggested main-package structure:

```text
lib/
├── flutter_local_device_discovery.dart
└── src/
    ├── discovery/
    │   ├── flutter_local_device_discovery.dart
    │   ├── local_discovery_request.dart
    │   ├── local_discovery_session.dart
    │   ├── local_discovery_snapshot.dart
    │   ├── local_discovery_event.dart
    │   ├── local_discovery_mode.dart
    │   └── local_discovery_protocol.dart
    ├── models/
    │   ├── local_device.dart
    │   ├── local_service.dart
    │   ├── local_device_identity.dart
    │   ├── local_device_vendor.dart
    │   ├── local_device_type.dart
    │   ├── local_device_capability.dart
    │   ├── local_device_reachability.dart
    │   ├── local_network_interface.dart
    │   └── internet_address_value.dart
    ├── aggregation/
    │   ├── local_device_observation.dart
    │   ├── device_aggregator.dart
    │   ├── device_deduplicator.dart
    │   ├── device_merge_decision.dart
    │   └── device_id_builder.dart
    ├── classification/
    │   ├── local_device_classifier.dart
    │   ├── default_device_classifier.dart
    │   ├── classification_rule.dart
    │   └── capability_evidence.dart
    ├── protocols/
    │   ├── service_type.dart
    │   ├── common_service_types.dart
    │   ├── ssdp_models.dart
    │   ├── upnp_models.dart
    │   └── ws_discovery_models.dart
    ├── registration/
    │   ├── local_service_registration.dart
    │   ├── registered_local_service.dart
    │   └── flutter_peer_advertisement.dart
    ├── filters/
    │   ├── device_filter.dart
    │   └── service_filter.dart
    ├── permissions/
    │   ├── discovery_readiness.dart
    │   ├── discovery_requirement.dart
    │   └── permission_guidance.dart
    ├── diagnostics/
    │   ├── discovery_diagnostics.dart
    │   ├── protocol_discovery_summary.dart
    │   └── discovery_warning.dart
    ├── errors/
    │   ├── discovery_exception.dart
    │   ├── discovery_error_code.dart
    │   └── native_error_mapper.dart
    ├── logging/
    │   ├── discovery_logger.dart
    │   └── no_op_discovery_logger.dart
    └── utils/
        ├── txt_record_codec.dart
        ├── local_address_classifier.dart
        ├── service_type_validator.dart
        └── immutable_collection_helpers.dart
```

Adjust the structure where needed, but preserve separation of responsibilities.

---

# 44. Platform-Interface Requirements

The platform-interface package must use `plugin_platform_interface`.

Suggested contract:

```dart
abstract class FlutterLocalDeviceDiscoveryPlatform
    extends PlatformInterface {
  Future<LocalDiscoveryCapabilities> getCapabilities();

  Future<NativeDiscoveryReadiness> checkReadiness(
    NativeDiscoveryRequest request,
  );

  Future<String> startDiscovery(
    NativeDiscoveryRequest request,
  );

  Stream<NativeDiscoveryEvent> eventsForSession(
    String sessionId,
  );

  Future<void> pauseDiscovery(String sessionId);

  Future<void> resumeDiscovery(String sessionId);

  Future<void> stopDiscovery(String sessionId);

  Future<NativeServiceRegistrationResult> registerService(
    NativeServiceRegistration request,
  );

  Future<void> updateRegisteredService(
    String registrationId,
    Map<String, Uint8List> txtRecords,
  );

  Future<void> unregisterService(String registrationId);

  Future<NativeDiscoveryDiagnostics> getDiagnostics();
}
```

Provide a mock implementation for tests.

Follow federated-plugin best practices.

---

# 45. Public Exports

Export only intended public APIs.

Do not expose:

* Native channel DTOs
* Internal packet parsers
* Internal aggregation mutable state
* Platform-specific implementation classes
* Native error payloads
* Debug-only helpers

Provide a clean barrel file:

```dart
library flutter_local_device_discovery;

export 'src/discovery/flutter_local_device_discovery.dart';
export 'src/discovery/local_discovery_request.dart';
export 'src/discovery/local_discovery_session.dart';
export 'src/discovery/local_discovery_snapshot.dart';
export 'src/discovery/local_discovery_event.dart';
export 'src/discovery/local_discovery_mode.dart';
export 'src/discovery/local_discovery_protocol.dart';

export 'src/models/local_device.dart';
export 'src/models/local_service.dart';
export 'src/models/local_device_identity.dart';
export 'src/models/local_device_type.dart';
export 'src/models/local_device_capability.dart';
export 'src/models/local_device_reachability.dart';
export 'src/models/local_network_interface.dart';
export 'src/models/internet_address_value.dart';

export 'src/registration/local_service_registration.dart';
export 'src/registration/registered_local_service.dart';

export 'src/filters/device_filter.dart';
export 'src/permissions/discovery_readiness.dart';
export 'src/diagnostics/discovery_diagnostics.dart';
export 'src/errors/discovery_exception.dart';
```

---

# 46. Example Application

Build a polished Material 3 example application.

The example app must demonstrate real devices and protocols, not only mocked data.

## Main screens

### Dashboard

Display:

* Current network status
* Active interface
* Discovery readiness
* Supported protocols
* Active session state
* Number of devices
* Number of services
* Discovery duration

### Device Discovery

Provide:

* Start and stop
* Snapshot and continuous modes
* Protocol selection
* Service-type selection
* IPv4 and IPv6 controls
* UPnP metadata toggle
* Safe probing toggle with warning
* Live device cards
* Filtering
* Sorting
* Search
* Pull to refresh
* Empty state
* Error state

### Device Details

Display:

* Device name
* Type
* Confidence
* Addresses
* Hostname
* Interfaces
* Services
* Ports
* Capabilities
* Manufacturer
* Model
* Identity evidence
* Discovery protocols
* First seen
* Last seen
* Reachability
* TXT records
* UPnP data
* WS-Discovery data
* Raw metadata in a sanitized expandable view

### Services Screen

Group by:

* Service type
* Device
* Protocol
* Interface

### Service Advertisement

Allow advertisement of:

```text
_flutter-device._tcp
_http._tcp
```

Use safe demonstration metadata.

### Diagnostics

Show:

* Platform capabilities
* Permissions
* Active native engines
* Protocol summaries
* Resolution counts
* Warnings
* Sanitized export

### Settings

Provide:

* Discovery duration
* Resolve timeout
* Grace period
* Protocol defaults
* Metadata fetching
* Interface inclusion
* Safe probe ports
* Debug logging
* Result limits

---

# 47. UI Requirements for Example App

The example must be:

* Professional
* Clean
* Modern
* Responsive
* Desktop-friendly
* Mobile-friendly
* Material 3
* Dark-mode compatible
* Keyboard accessible
* Screen-reader compatible
* RTL compatible
* Large-text compatible

Do not hardcode colors.

Use cards, data tables, expandable panels, and responsive layouts appropriately.

Do not turn the main package into a UI package.

Example UI components must remain inside the example application.

---

# 48. Tests

Create comprehensive tests.

## Dart unit tests

Test:

* Service-type validation
* TXT-record encoding and decoding
* IPv4 classification
* IPv6 classification
* Private-address detection
* Link-local detection
* Device-ID generation
* Device deduplication
* Device merging
* Conflicting identifiers
* Classification rules
* Capability inference
* Snapshot aggregation
* Event ordering
* Lost-device grace periods
* TTL expiry
* Filter logic
* Error mapping
* JSON serialization
* Immutable model equality
* Configuration validation

## Platform-interface tests

Test:

* Default implementation
* Mock platform replacement
* Unsupported methods
* Session lifecycle
* Multiple sessions
* Registration lifecycle
* Error propagation

## Android tests

Test:

* NSD start and stop
* Discovery callback mapping
* Service resolution
* Lost-service handling
* Multicast-lock release
* Network change handling
* Engine detach cleanup
* Invalid service type
* Repeated stop calls
* Permission/configuration failures

## Apple tests

Test:

* Browser start and stop
* Result-change handling
* Endpoint conversion
* TXT-record conversion
* Network-path changes
* Cancellation
* Service registration
* Local Network error mapping
* Missing Bonjour declaration guidance
* Lifecycle cleanup

## Windows tests

Test:

* DNS-SD watcher lifecycle
* Datagram discovery
* Adapter enumeration
* Network-status changes
* SSDP parsing
* WS-Discovery parsing
* IPv4 and IPv6 conversion
* COM/resource cleanup
* Cancellation
* Firewall-related error guidance where observable

## Parser tests

Use fixture-based tests for:

* SSDP responses
* UPnP XML
* WS-Discovery XML
* Malformed XML
* XML entity attack payloads
* Oversized metadata
* Duplicate headers
* Mixed header casing
* Invalid locations
* IPv6 locations
* Invalid TXT bytes
* Large TXT records

## Integration tests

Where feasible, create local test services that:

* Advertise mDNS/DNS-SD
* Respond to SSDP
* Serve safe UPnP description XML
* Respond to WS-Discovery
* Appear and disappear
* Change TXT records
* Change IP addresses

Do not make tests depend on public internet access.

---

# 49. Test Utilities

Provide an optional testing library:

```dart
import 'package:flutter_local_device_discovery/testing.dart';
```

Include:

* Fake platform
* Fake discovery session
* Device fixtures
* Service fixtures
* Event sequence builder
* Snapshot builder
* Matchers
* Simulated TTL expiration
* Simulated network changes
* Simulated permission failure

Do not expose test utilities from the main library.

---

# 50. Code Quality

Use:

* Sound null safety
* Strong typing
* Immutable public models
* Sealed classes
* Exhaustive switches
* Const constructors
* Small focused files
* Clear naming
* Native availability checks
* Structured concurrency
* Explicit cancellation
* Dependency inversion
* Typed errors
* Complete Dart documentation

Avoid:

* `dynamic` in public APIs
* Unbounded streams
* Global mutable state
* Forced singletons
* Empty catch blocks
* Swallowed native exceptions
* Deprecated APIs without compatibility justification
* Hardcoded visible strings
* Hardcoded timeouts without configuration
* Platform checks spread through the Dart API
* Raw `Map<dynamic, dynamic>` models
* Unimplemented public methods
* Production TODOs
* Debug prints
* Blocking calls on UI threads

---

# 51. Documentation

Document every public API.

Each public class and method should explain:

* Purpose
* Platform behavior
* Parameters
* Return value
* Events
* Exceptions
* Permission requirements
* Lifecycle behavior
* Security implications
* Limitations
* Example usage

Use accurate terminology:

* Discovery is not pairing
* Discovery is not authentication
* Discovery is not guaranteed inventory
* Reachability is not availability
* No response does not always mean offline
* Device classification may be inferred
* MAC addresses may be unavailable
* Multicast may be blocked
* Guest, enterprise, and isolated networks may prevent peer discovery

---

# 52. README Structure

Create a complete professional README containing:

1. Package overview
2. Why this package exists
3. Key features
4. Supported platforms
5. Supported protocols
6. Device types
7. Architecture overview
8. Installation
9. Quick start
10. Snapshot discovery
11. Continuous discovery
12. Custom service types
13. Device filtering
14. Service resolution
15. UPnP metadata
16. WS-Discovery
17. Safe host probing
18. Service advertisement
19. Flutter peer discovery
20. Android configuration
21. iOS configuration
22. macOS configuration
23. Windows configuration
24. Permissions
25. Network-interface behavior
26. IPv4 and IPv6
27. Security considerations
28. Privacy considerations
29. Performance guidance
30. Diagnostics
31. Error handling
32. Testing
33. Example app
34. Troubleshooting
35. Comparison with basic mDNS packages
36. Known limitations
37. Roadmap
38. Contribution
39. Security reporting
40. License

Include copy-paste-ready examples.

---

# 53. Comparison Section

The README may include a neutral comparison explaining that this plugin is intended to provide:

* mDNS
* DNS-SD
* SSDP
* UPnP metadata
* WS-Discovery
* Device-level aggregation
* Classification
* Deduplication
* Presence monitoring
* Network-interface awareness
* Service advertisement
* Diagnostics

Do not attack or make unsupported claims about other packages.

Do not call competitors abandoned without evidence.

---

# 54. Pub.dev Metadata

Prepare a pub.dev-ready `pubspec.yaml`.

Suggested description:

```yaml
description: >
  Native local-network device and service discovery for Flutter using
  mDNS, DNS-SD, Bonjour, SSDP, UPnP and WS-Discovery across Android,
  iOS, macOS and Windows.
```

Suggested topics:

```yaml
topics:
  - device-discovery
  - local-network
  - mdns
  - upnp
  - networking
```

Use a professional repository structure.

Include:

* Homepage
* Repository
* Issue tracker
* Documentation URL where available
* Screenshots
* Example
* Platform declarations
* Funding link if desired
* MIT or BSD-3-Clause license

Do not include placeholder URLs in the final publishable version.

---

# 55. Repository Files

Include:

```text
README.md
CHANGELOG.md
LICENSE
CONTRIBUTING.md
CODE_OF_CONDUCT.md
SECURITY.md
ROADMAP.md
ARCHITECTURE.md
PRIVACY.md
analysis_options.yaml
melos.yaml
pubspec.yaml
.github/
    ISSUE_TEMPLATE/
    PULL_REQUEST_TEMPLATE.md
    workflows/
```

Create issue templates for:

* Bug report
* Feature request
* New protocol proposal
* Device compatibility report
* Platform issue
* Security report guidance

Security reports must not be filed publicly when they contain exploitable details.

---

# 56. Monorepo Tooling

Use Melos or an equivalent monorepo workflow.

Provide commands for:

```bash
melos bootstrap
melos run analyze
melos run test
melos run format
melos run publish-dry-run
```

Keep scripts cross-platform.

Do not assume Bash exists on Windows.

---

# 57. Continuous Integration

Create GitHub Actions workflows.

## Main CI

Run on:

* Ubuntu
* macOS
* Windows

Steps:

```text
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter pub publish --dry-run
```

Adapt commands for the monorepo.

## Native validation

Include:

* Android Gradle build
* iOS build without code signing
* macOS build
* Windows build
* Native unit tests
* Pigeon generation validation
* No uncommitted generated-code changes

## Additional workflows

Add:

* Dependency review
* CodeQL where appropriate
* Documentation generation
* Coverage
* Release validation
* Conventional commit or release-note validation
* Automated pub score checks where practical

Never expose signing secrets.

---

# 58. Version Plan

## `0.1.0`

Implement:

* Federated architecture
* Android
* iOS
* macOS
* Windows foundations
* mDNS/DNS-SD/Bonjour
* Service browsing
* Service resolution
* Device and service models
* Continuous and snapshot sessions
* Network-interface models
* Basic deduplication
* Basic classification
* Example application
* Core tests
* Documentation

## `0.2.0`

Add:

* SSDP
* UPnP description parsing
* Better device aggregation
* Capability evidence
* Metadata security policies
* Additional tests

## `0.3.0`

Add:

* WS-Discovery
* ONVIF-oriented discovery metadata
* Improved Windows support
* Protocol diagnostics
* Device presence improvements

## `0.4.0`

Add:

* Service registration
* Flutter peer advertisement
* TXT-record updates
* Pairing metadata helpers

## `0.5.0`

Add:

* Optional safe host discovery
* Neighbor-table support where permitted
* Safe limited port probing
* Reachability model

## `1.0.0`

Require:

* Stable public API
* Production-tested native resource lifecycle
* Strong parser security
* IPv4 and IPv6 testing
* Multiple-interface testing
* Comprehensive documentation
* Professional example app
* Migration guide
* Pub.dev dry run passing
* No unresolved critical issues
* No incomplete platform implementation

---

# 59. Non-Goals

Do not turn this package into:

* A vulnerability scanner
* A penetration-testing framework
* A port-scanning suite
* A password-recovery tool
* A device-exploitation framework
* A router administration SDK
* A surveillance tool
* A packet sniffer
* A VPN
* A remote-control SDK
* A DLNA control SDK
* A printer control SDK
* A camera streaming SDK
* An authentication system
* A pairing system
* A cloud device registry

The package discovers and describes local devices and services.

Control functionality belongs in separate packages.

---

# 60. Acceptance Criteria

The package is complete only when:

* Android uses native NSD and network APIs.
* iOS uses modern Apple networking APIs.
* macOS supports native Bonjour discovery.
* Windows uses native Windows networking APIs.
* mDNS/DNS-SD discovery works.
* SSDP discovery works.
* UPnP descriptions are parsed safely.
* WS-Discovery works where implemented.
* Snapshot discovery works.
* Continuous monitoring works.
* Multiple sessions work.
* Discovery can be cancelled.
* All native resources are released.
* Device and service results are strongly typed.
* IPv4 and IPv6 are represented correctly.
* TXT-record raw bytes are preserved.
* Device results are deduplicated.
* Classification includes confidence and evidence.
* Network changes are reported.
* Lost devices use a grace period.
* Service registration works on supported platforms.
* Unsupported features return typed errors.
* Permissions are accurately documented.
* Apple Local Network configuration is documented.
* Android multicast handling is leak-free.
* Windows firewall limitations are documented.
* Malformed packets do not crash the plugin.
* Malicious XML does not trigger unsafe parsing.
* Metadata fetching is bounded and cancellable.
* No Dart or native UI thread is blocked.
* No analytics or telemetry is included.
* Public APIs have complete documentation.
* Example app demonstrates real discovery.
* Unit tests pass.
* Native tests pass.
* Flutter analysis passes.
* Formatting passes.
* Platform builds pass.
* Pub.dev dry run passes.
* README, changelog, security policy, and contribution files are complete.
* The package contains no placeholder implementations.
* The package contains no production `TODO` or `UnimplementedError`.
* The repository is ready for public community contribution.

---

# 61. Implementation Order

Implement in this order:

```text
1. Create federated monorepo
2. Define public Dart models
3. Define platform interface
4. Generate typed Pigeon channels
5. Implement session lifecycle
6. Implement Android NSD
7. Implement Apple Bonjour browsing
8. Implement Windows DNS-SD browsing
9. Normalize native service events
10. Add service resolution
11. Add network-interface monitoring
12. Implement device observation model
13. Implement deduplication
14. Implement classification
15. Implement snapshot mode
16. Implement continuous mode
17. Add diagnostics
18. Add SSDP
19. Add secure UPnP XML parsing
20. Add WS-Discovery
21. Add service registration
22. Add safe optional host discovery
23. Build polished example app
24. Add native and Dart tests
25. Complete documentation
26. Configure CI
27. Run pub.dev dry run
28. Perform API review
29. Prepare initial release
```

Do not begin with every protocol simultaneously.

Complete and test each layer before adding the next.

---

# 62. Final Engineering Instruction

Build a real native Flutter plugin, not a conceptual demo.

Do not produce only architecture documents.

Generate:

* Complete Dart source code
* Kotlin implementation
* Swift implementation
* C++/WinRT implementation
* Pigeon definitions
* Federated platform packages
* Example application
* Unit tests
* Native tests
* Integration tests
* CI workflows
* README
* Changelog
* License
* Contribution guide
* Security policy
* Privacy documentation
* Architecture documentation
* Pub.dev metadata

Where a platform feature is unavailable:

* Do not fake it.
* Do not silently ignore it.
* Return a typed unsupported result.
* Document the limitation.
* Keep API behavior consistent.

Where native APIs differ:

* Preserve a unified high-level API.
* Expose platform-specific details only through optional metadata.
* Avoid reducing all platforms to the weakest implementation.
* Use capability detection.
* Use availability checks.
* Maintain safe defaults.

The final package must be:

```text
Native-first
Cross-platform
Secure
Performant
Extensible
Well-tested
Professionally documented
Pub.dev ready
Community friendly
```

The package’s main identity should be:

> One native Flutter API for discovering and understanding devices and services on the local network.
