## 0.2.0 - 2026-08-09

* Aligned the Windows implementation with platform interface 0.2.0.
* Added an event channel fallback so shared SSDP/UPnP sessions can run without `MissingPluginException`.
* Added safe pause and resume handling for shared-engine sessions.
* Corrected capability reporting while native Windows DNS-SD remains unimplemented.
* Updated native diagnostic version reporting to 0.2.0.

## 0.1.0 - 2026-08-06

* Initial Windows implementation foundation.
* Added Winsock setup and native network-interface diagnostics.
