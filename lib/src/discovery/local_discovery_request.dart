import '../models/local_device.dart';
import '../models/local_device_capability.dart';
import '../models/local_device_type.dart';
import '../models/metadata_security_policy.dart';
import '../utils/service_type_validator.dart';
import 'local_discovery_mode.dart';
import 'local_discovery_protocol.dart';

/// Configuration for a discovery session.
class LocalDiscoveryRequest {
  const LocalDiscoveryRequest({
    this.mode = LocalDiscoveryMode.snapshot,
    this.protocols = const {
      LocalDiscoveryProtocol.mdns,
      LocalDiscoveryProtocol.dnsSd,
    },
    this.serviceTypes = const <String>{},
    this.ssdpSearchTargets = const <String>{},
    this.wsDiscoveryTypes = const <String>{},
    this.duration = const Duration(seconds: 8),
    this.resolveTimeout = const Duration(seconds: 3),
    this.metadataTimeout = const Duration(seconds: 3),
    this.lostDeviceGracePeriod = const Duration(seconds: 10),
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
    this.metadataSecurityPolicy = MetadataSecurityPolicy.defaultPolicy,
    this.maxDevices = 100,
    this.maxServices = 500,
    this.safePortProbe,
    this.hostDiscovery,
    this.filter,
    this.metadata = const <String, Object?>{},
  });

  /// The mode of this discovery session.
  final LocalDiscoveryMode mode;

  /// The protocols to use for discovery.
  final Set<LocalDiscoveryProtocol> protocols;

  /// The service types to browse for (e.g., `_http._tcp`).
  final Set<String> serviceTypes;

  /// The SSDP search targets to use.
  final Set<String> ssdpSearchTargets;

  /// Reserved WS-Discovery types.
  final Set<String> wsDiscoveryTypes;

  /// The maximum duration of a snapshot discovery.
  final Duration duration;

  /// The timeout for resolving a service.
  final Duration resolveTimeout;

  /// The timeout for fetching metadata.
  final Duration metadataTimeout;

  /// The grace period before a device is considered lost.
  final Duration lostDeviceGracePeriod;

  /// Whether to resolve discovered services.
  final bool resolveServices;

  /// Whether to fetch UPnP device descriptions.
  final bool fetchUpnpDescriptions;

  /// Whether to include IPv4 addresses.
  final bool includeIpv4;

  /// Whether to include IPv6 addresses.
  final bool includeIpv6;

  /// Whether to include loopback interfaces.
  final bool includeLoopback;

  /// Whether to include link-local addresses.
  final bool includeLinkLocal;

  /// Whether to include VPN interfaces.
  final bool includeVpnInterfaces;

  /// Whether to include cellular interfaces.
  final bool includeCellularInterfaces;

  /// Whether to include peer-to-peer interfaces.
  final bool includePeerToPeer;

  /// Whether to deduplicate results.
  final bool deduplicateResults;

  /// Whether to classify devices.
  final bool classifyDevices;

  /// Whether to monitor network changes.
  final bool monitorNetworkChanges;

  /// Security limits applied to UPnP description downloads and XML parsing.
  final MetadataSecurityPolicy metadataSecurityPolicy;

  /// Maximum number of devices retained by a session.
  final int maxDevices;

  /// Maximum number of services retained by a session.
  final int maxServices;

  /// Configuration for safe TCP port probing.
  final SafePortProbeConfig? safePortProbe;

  /// Configuration for host discovery via neighbor table and reachability probing.
  final HostDiscoveryConfig? hostDiscovery;

  /// Optional device filter.
  final DeviceFilter? filter;

  /// Additional metadata for this request.
  final Map<String, Object?> metadata;

  /// Validates this request.
  ///
  /// Throws an [ArgumentError] if the request is invalid.
  void validate() {
    if (protocols.isEmpty) {
      throw ArgumentError('at least one discovery protocol is required');
    }
    if (duration <= Duration.zero) {
      throw ArgumentError('duration must be positive');
    }
    if (resolveTimeout <= Duration.zero) {
      throw ArgumentError('resolveTimeout must be positive');
    }
    if (metadataTimeout <= Duration.zero) {
      throw ArgumentError('metadataTimeout must be positive');
    }
    if (lostDeviceGracePeriod < Duration.zero) {
      throw ArgumentError('lostDeviceGracePeriod must not be negative');
    }
    if (maxDevices <= 0) {
      throw ArgumentError('maxDevices must be positive');
    }
    if (maxServices <= 0) {
      throw ArgumentError('maxServices must be positive');
    }
    if (metadataSecurityPolicy.maxRedirects < 0 ||
        metadataSecurityPolicy.maxResponseSizeBytes <= 0 ||
        metadataSecurityPolicy.timeoutDuration <= Duration.zero ||
        metadataSecurityPolicy.maxXmlNestingDepth <= 0) {
      throw ArgumentError('metadataSecurityPolicy contains invalid limits');
    }
    for (final serviceType in serviceTypes) {
      if (!ServiceTypeValidator.isValid(serviceType)) {
        throw ArgumentError('Invalid service type: $serviceType');
      }
    }
    for (final target in ssdpSearchTargets) {
      if (target.trim().isEmpty ||
          target.length > 512 ||
          target.contains('\r') ||
          target.contains('\n')) {
        throw ArgumentError('Invalid SSDP search target: $target');
      }
    }
  }
}

/// Configuration for safe TCP port probing during discovery.
class SafePortProbeConfig {
  const SafePortProbeConfig({
    this.ports = const <int>[],
    this.perHostTimeout = const Duration(seconds: 2),
    this.globalTimeout = const Duration(seconds: 10),
    this.maxConcurrentProbes = 8,
  });

  /// The ports to probe.
  final List<int> ports;

  /// The timeout for each host probe.
  final Duration perHostTimeout;

  /// The global timeout for all probes.
  final Duration globalTimeout;

  /// The maximum number of concurrent probes.
  final int maxConcurrentProbes;
}

/// Configuration for host discovery via neighbor table and ICMP reachability.
class HostDiscoveryConfig {
  const HostDiscoveryConfig({
    this.enabled = false,
    this.useNeighborTable = true,
    this.useReachability = false,
    this.addressRanges = const <String>[],
  });

  /// Whether host discovery is enabled.
  final bool enabled;

  /// Whether to use the neighbor table.
  final bool useNeighborTable;

  /// Whether to use ICMP reachability.
  final bool useReachability;

  /// Address ranges to probe (CIDR notation).
  final List<String> addressRanges;
}

/// A filter for devices.
class DeviceFilter {
  const DeviceFilter({
    this.types,
    this.capabilities,
    this.protocols,
    this.serviceTypes,
    this.hostnames,
    this.manufacturers,
    this.ports,
    this.predicate,
  });

  /// Filter by device types.
  final Set<LocalDeviceType>? types;

  /// Filter by device capabilities.
  final Set<LocalDeviceCapability>? capabilities;

  /// Filter by discovery protocols.
  final Set<LocalDiscoveryProtocol>? protocols;

  /// Filter by service types.
  final Set<String>? serviceTypes;

  /// Filter by hostnames.
  final Set<String>? hostnames;

  /// Filter by manufacturers.
  final Set<String>? manufacturers;

  /// Filter by ports.
  final Set<int>? ports;

  /// A custom predicate for filtering.
  final bool Function(LocalDevice device)? predicate;

  /// Whether this filter matches the given device.
  bool matches(LocalDevice device) {
    if (types != null && !types!.contains(device.type)) return false;
    if (capabilities != null &&
        !device.capabilities.any(capabilities!.contains)) {
      return false;
    }
    if (protocols != null && !device.discoveredBy.any(protocols!.contains)) {
      return false;
    }
    if (serviceTypes != null &&
        !device.services.any((s) => serviceTypes!.contains(s.serviceType))) {
      return false;
    }
    if (hostnames != null &&
        (device.hostname == null || !hostnames!.contains(device.hostname))) {
      return false;
    }
    if (manufacturers != null &&
        (device.identity.manufacturer == null ||
            !manufacturers!.contains(device.identity.manufacturer))) {
      return false;
    }
    if (ports != null &&
        !device.services.any(
          (s) => s.port != null && ports!.contains(s.port),
        )) {
      return false;
    }
    if (predicate != null && !predicate!(device)) return false;
    return true;
  }
}
