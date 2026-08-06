/// A serializable discovery request passed to native platforms.
class NativeDiscoveryRequest {
  const NativeDiscoveryRequest({
    required this.mode,
    this.protocols = const <int>[],
    this.serviceTypes = const <String>[],
    this.ssdpSearchTargets = const <String>[],
    this.wsDiscoveryTypes = const <String>[],
    this.durationMilliseconds = 8000,
    this.resolveTimeoutMilliseconds = 3000,
    this.metadataTimeoutMilliseconds = 3000,
    this.lostDeviceGracePeriodMilliseconds = 10000,
    this.resolveServices = true,
    this.fetchUpnpDescriptions = false,
    this.includeIpv4 = true,
    this.includeIpv6 = true,
    this.includeLoopback = false,
    this.includeLinkLocal = true,
    this.includeVpnInterfaces = false,
    this.includeCellularInterfaces = false,
    this.includePeerToPeer = false,
    this.deduplicateResults = true,
    this.classifyDevices = true,
    this.monitorNetworkChanges = true,
    this.maxDevices = 100,
    this.maxServices = 500,
    this.metadata = const <String, Object?>{},
  });

  final int mode;
  final List<int> protocols;
  final List<String> serviceTypes;
  final List<String> ssdpSearchTargets;
  final List<String> wsDiscoveryTypes;
  final int durationMilliseconds;
  final int resolveTimeoutMilliseconds;
  final int metadataTimeoutMilliseconds;
  final int lostDeviceGracePeriodMilliseconds;
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
  final int maxDevices;
  final int maxServices;
  final Map<String, Object?> metadata;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'mode': mode,
      'protocols': protocols,
      'serviceTypes': serviceTypes,
      'ssdpSearchTargets': ssdpSearchTargets,
      'wsDiscoveryTypes': wsDiscoveryTypes,
      'durationMilliseconds': durationMilliseconds,
      'resolveTimeoutMilliseconds': resolveTimeoutMilliseconds,
      'metadataTimeoutMilliseconds': metadataTimeoutMilliseconds,
      'lostDeviceGracePeriodMilliseconds': lostDeviceGracePeriodMilliseconds,
      'resolveServices': resolveServices,
      'fetchUpnpDescriptions': fetchUpnpDescriptions,
      'includeIpv4': includeIpv4,
      'includeIpv6': includeIpv6,
      'includeLoopback': includeLoopback,
      'includeLinkLocal': includeLinkLocal,
      'includeVpnInterfaces': includeVpnInterfaces,
      'includeCellularInterfaces': includeCellularInterfaces,
      'includePeerToPeer': includePeerToPeer,
      'deduplicateResults': deduplicateResults,
      'classifyDevices': classifyDevices,
      'monitorNetworkChanges': monitorNetworkChanges,
      'maxDevices': maxDevices,
      'maxServices': maxServices,
      'metadata': metadata,
    };
  }

  static Map<String, Object?> _stringMap(Object? value) {
    if (value is Map<Object?, Object?>) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return const {};
  }

  static NativeDiscoveryRequest fromMap(Map<Object?, Object?> map) {
    return NativeDiscoveryRequest(
      mode: map['mode']! as int,
      protocols: (map['protocols'] as List<Object?>? ?? const [])
          .whereType<int>()
          .toList(),
      serviceTypes: (map['serviceTypes'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(),
      ssdpSearchTargets:
          (map['ssdpSearchTargets'] as List<Object?>? ?? const [])
              .whereType<String>()
              .toList(),
      wsDiscoveryTypes:
          (map['wsDiscoveryTypes'] as List<Object?>? ?? const [])
              .whereType<String>()
              .toList(),
      durationMilliseconds: map['durationMilliseconds'] as int? ?? 8000,
      resolveTimeoutMilliseconds:
          map['resolveTimeoutMilliseconds'] as int? ?? 3000,
      metadataTimeoutMilliseconds:
          map['metadataTimeoutMilliseconds'] as int? ?? 3000,
      lostDeviceGracePeriodMilliseconds:
          map['lostDeviceGracePeriodMilliseconds'] as int? ?? 10000,
      resolveServices: map['resolveServices'] as bool? ?? true,
      fetchUpnpDescriptions: map['fetchUpnpDescriptions'] as bool? ?? false,
      includeIpv4: map['includeIpv4'] as bool? ?? true,
      includeIpv6: map['includeIpv6'] as bool? ?? true,
      includeLoopback: map['includeLoopback'] as bool? ?? false,
      includeLinkLocal: map['includeLinkLocal'] as bool? ?? true,
      includeVpnInterfaces: map['includeVpnInterfaces'] as bool? ?? false,
      includeCellularInterfaces:
          map['includeCellularInterfaces'] as bool? ?? false,
      includePeerToPeer: map['includePeerToPeer'] as bool? ?? false,
      deduplicateResults: map['deduplicateResults'] as bool? ?? true,
      classifyDevices: map['classifyDevices'] as bool? ?? true,
      monitorNetworkChanges: map['monitorNetworkChanges'] as bool? ?? true,
      maxDevices: map['maxDevices'] as int? ?? 100,
      maxServices: map['maxServices'] as int? ?? 500,
      metadata: _stringMap(map['metadata']),
    );
  }
}