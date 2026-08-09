/// The discovery protocol used to discover a device or service.
enum LocalDiscoveryProtocol {
  /// Multicast DNS.
  mdns,

  /// DNS-Based Service Discovery.
  dnsSd,

  /// Bonjour (Apple's implementation of mDNS/DNS-SD).
  bonjour,

  /// Simple Service Discovery Protocol.
  ssdp,

  /// UPnP Device Description.
  upnp,

  /// WS-Discovery, reserved for a future release.
  ///
  /// This protocol is not implemented in v0.2.0.
  wsDiscovery,

  /// Neighbor table inspection, reserved for a future release.
  ///
  /// This protocol is not implemented in v0.2.0.
  neighborTable,

  /// ICMP reachability, reserved for a future release.
  ///
  /// This protocol is not implemented in v0.2.0.
  reachability,

  /// Safe port probing, reserved for a future release.
  ///
  /// This protocol is not implemented in v0.2.0.
  safePortProbe,
}
