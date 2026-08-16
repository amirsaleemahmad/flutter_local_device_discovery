/// Serializable platform capabilities.
class NativeDiscoveryCapabilities {
  const NativeDiscoveryCapabilities({
    this.supportedProtocols = const <int>[],
    this.supportsServiceRegistration = false,
    this.supportsIpv4 = true,
    this.supportsIpv6 = true,
    this.supportsMultipleInterfaces = true,
    this.supportsNetworkSpecificDiscovery = false,
    this.supportsNeighborTable = false,
    this.supportsReachability = false,
    this.supportsSafePortProbe = false,
    this.supportsCustomAdapters = true,
    this.supportsMulticastHealthCheck = true,
    this.supportsWifiBandDetection = false,
    this.requiresLocalNetworkPermission = false,
    this.requiresMulticastPermission = false,
    this.platformDetails = const <String, Object?>{},
  });

  final List<int> supportedProtocols;
  final bool supportsServiceRegistration;
  final bool supportsIpv4;
  final bool supportsIpv6;
  final bool supportsMultipleInterfaces;
  final bool supportsNetworkSpecificDiscovery;
  final bool supportsNeighborTable;
  final bool supportsReachability;
  final bool supportsSafePortProbe;
  final bool supportsCustomAdapters;
  final bool supportsMulticastHealthCheck;
  final bool supportsWifiBandDetection;
  final bool requiresLocalNetworkPermission;
  final bool requiresMulticastPermission;
  final Map<String, Object?> platformDetails;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'supportedProtocols': supportedProtocols,
      'supportsServiceRegistration': supportsServiceRegistration,
      'supportsIpv4': supportsIpv4,
      'supportsIpv6': supportsIpv6,
      'supportsMultipleInterfaces': supportsMultipleInterfaces,
      'supportsNetworkSpecificDiscovery': supportsNetworkSpecificDiscovery,
      'supportsNeighborTable': supportsNeighborTable,
      'supportsReachability': supportsReachability,
      'supportsSafePortProbe': supportsSafePortProbe,
      'supportsCustomAdapters': supportsCustomAdapters,
      'supportsMulticastHealthCheck': supportsMulticastHealthCheck,
      'supportsWifiBandDetection': supportsWifiBandDetection,
      'requiresLocalNetworkPermission': requiresLocalNetworkPermission,
      'requiresMulticastPermission': requiresMulticastPermission,
      'platformDetails': platformDetails,
    };
  }

  static Map<String, Object?> _stringMap(Object? value) {
    if (value is Map<Object?, Object?>) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return const {};
  }

  static NativeDiscoveryCapabilities fromMap(Map<Object?, Object?> map) {
    return NativeDiscoveryCapabilities(
      supportedProtocols:
          (map['supportedProtocols'] as List<Object?>? ?? const [])
              .whereType<int>()
              .toList(),
      supportsServiceRegistration:
          map['supportsServiceRegistration'] as bool? ?? false,
      supportsIpv4: map['supportsIpv4'] as bool? ?? true,
      supportsIpv6: map['supportsIpv6'] as bool? ?? true,
      supportsMultipleInterfaces:
          map['supportsMultipleInterfaces'] as bool? ?? true,
      supportsNetworkSpecificDiscovery:
          map['supportsNetworkSpecificDiscovery'] as bool? ?? false,
      supportsNeighborTable: map['supportsNeighborTable'] as bool? ?? false,
      supportsReachability: map['supportsReachability'] as bool? ?? false,
      supportsSafePortProbe: map['supportsSafePortProbe'] as bool? ?? false,
      supportsCustomAdapters: map['supportsCustomAdapters'] as bool? ?? true,
      supportsMulticastHealthCheck:
          map['supportsMulticastHealthCheck'] as bool? ?? true,
      supportsWifiBandDetection:
          map['supportsWifiBandDetection'] as bool? ?? false,
      requiresLocalNetworkPermission:
          map['requiresLocalNetworkPermission'] as bool? ?? false,
      requiresMulticastPermission:
          map['requiresMulticastPermission'] as bool? ?? false,
      platformDetails: _stringMap(map['platformDetails']),
    );
  }
}
