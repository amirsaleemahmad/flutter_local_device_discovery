## 0.2.0

* Added SSDP (Simple Service Discovery Protocol) support.
* Added UPnP device description parsing.
* Added better device aggregation with cross-protocol deduplication.
* Added capability evidence tracking.
* Added metadata security policies for safe UPnP fetching.
* Added `SsdpDevice` model for SSDP-discovered devices.
* Added `UpnpDeviceDescription` model for parsed UPnP descriptions.
* Added `CapabilityEvidence` model for tracking device capability sources.
* Added `MetadataSecurityPolicy` for bounded, safe metadata fetching.
* Added `DeviceAggregator` for merging devices from multiple protocols.
* Added `copyWith` to `LocalDevice` for immutable updates.
* Added unit tests for SSDP, UPnP, aggregator, and security policy.
* Updated all subpackage versions to 0.2.0.

## 0.1.0

* Initial release of `flutter_local_device_discovery`.
* Federated plugin architecture with platform interface.
* Android implementation using native NSD (Network Service Discovery).
* iOS and macOS implementation using Apple's Network framework (NWBrowser).
* Windows implementation foundation with Winsock and network interface enumeration.
* mDNS/DNS-SD/Bonjour service browsing and resolution.
* Device and service models with strong typing.
* Continuous and snapshot discovery sessions.
* Network-interface models.
* Basic device deduplication and classification.
* Service-type validation.
* Internet address parsing and classification.
* Core unit tests.
* Documentation.
