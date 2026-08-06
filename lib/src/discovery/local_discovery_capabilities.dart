import 'local_discovery_protocol.dart';

/// The capabilities supported by the current platform.
class LocalDiscoveryCapabilities {
  const LocalDiscoveryCapabilities({
    this.supportedProtocols = const <LocalDiscoveryProtocol>{},
    this.supportsServiceRegistration = false,
    this.supportsIpv4 = true,
    this.supportsIpv6 = true,
    this.supportsMultipleInterfaces = true,
    this.supportsNetworkSpecificDiscovery = false,
    this.supportsNeighborTable = false,
    this.supportsReachability = false,
    this.supportsSafePortProbe = false,
    this.requiresLocalNetworkPermission = false,
    this.requiresMulticastPermission = false,
    this.platformDetails = const <String, Object?>{},
  });

  /// The protocols supported by this platform.
  final Set<LocalDiscoveryProtocol> supportedProtocols;

  /// Whether this platform supports service registration.
  final bool supportsServiceRegistration;

  /// Whether this platform supports IPv4.
  final bool supportsIpv4;

  /// Whether this platform supports IPv6.
  final bool supportsIpv6;

  /// Whether this platform supports multiple network interfaces.
  final bool supportsMultipleInterfaces;

  /// Whether this platform supports network-specific discovery.
  final bool supportsNetworkSpecificDiscovery;

  /// Whether this platform supports neighbor table inspection.
  final bool supportsNeighborTable;

  /// Whether this platform supports reachability checks.
  final bool supportsReachability;

  /// Whether this platform supports safe port probing.
  final bool supportsSafePortProbe;

  /// Whether this platform requires local network permission.
  final bool requiresLocalNetworkPermission;

  /// Whether this platform requires multicast permission.
  final bool requiresMulticastPermission;

  /// Platform-specific details.
  final Map<String, Object?> platformDetails;

  /// Whether the given protocol is supported.
  bool supports(LocalDiscoveryProtocol protocol) {
    return supportedProtocols.contains(protocol);
  }
}