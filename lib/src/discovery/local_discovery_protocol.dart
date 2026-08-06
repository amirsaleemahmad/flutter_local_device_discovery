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

  /// WS-Discovery.
  wsDiscovery,

  /// Neighbor table inspection.
  neighborTable,

  /// ICMP reachability.
  reachability,

  /// Safe port probing.
  safePortProbe,
}