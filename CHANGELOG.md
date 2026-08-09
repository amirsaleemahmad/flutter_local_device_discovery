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
* Added integration and security tests for SSDP, UPnP, aggregation, session snapshots, and metadata fetching.

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
* Added service-type validation, basic deduplication, classification, tests, and documentation.
