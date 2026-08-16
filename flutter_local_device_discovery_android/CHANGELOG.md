## 1.1.0 - 2026-08-16

* Updated platform interface dependency to `^1.1.0`.

## 1.0.0 - 2026-08-11

* Aligned the Android implementation with platform interface 1.0.0.
* Added read-only ARP neighbor table inspection via `/proc/net/arp`.

## 0.3.0 - 2026-08-11

* Aligned the Android implementation with platform interface 0.3.0.

## 0.2.0 - 2026-08-09

* Aligned the Android implementation with platform interface 0.2.0.
* Fixed NSD discovery listeners not being stopped with their owning session.
* Fixed multicast locks not being released during session and engine cleanup.
* Made formatter-backed diagnostics safe across concurrent calls.
* Updated native diagnostic version reporting to 0.2.0.

## 0.1.0 - 2026-08-06

* Initial Android implementation.
* Added native NSD browsing and resolution for mDNS/DNS-SD services.
