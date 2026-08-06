/// The mode of a discovery session.
enum LocalDiscoveryMode {
  /// Discover advertised services without subnet probing.
  servicesOnly,

  /// Build device-level results from all enabled engines.
  devicesOnly,

  /// Return both device and service streams.
  servicesAndDevices,

  /// Continue monitoring additions, updates, removals, and network changes.
  continuous,

  /// Run for a defined duration and return one deduplicated result.
  snapshot,
}