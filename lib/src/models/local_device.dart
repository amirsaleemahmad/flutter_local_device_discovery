import 'internet_address_value.dart';
import 'capability_evidence.dart';
import 'local_device_capability.dart';
import 'local_device_identity.dart';
import 'local_device_type.dart';
import 'local_network_interface.dart';
import 'local_service.dart';
import '../discovery/local_discovery_protocol.dart';

/// A normalized device discovered on the local network.
class LocalDevice {
  const LocalDevice({
    required this.id,
    required this.displayName,
    this.hostname,
    this.addresses = const <InternetAddressValue>[],
    this.interfaces = const <LocalNetworkInterface>[],
    this.services = const <LocalService>[],
    this.type = LocalDeviceType.unknown,
    this.capabilities = const <LocalDeviceCapability>{},
    this.capabilityEvidence = const <CapabilityEvidence>[],
    this.identity = const LocalDeviceIdentity(),
    this.vendor,
    this.reachability = const LocalDeviceReachability.unknown(),
    this.discoveredBy = const <LocalDiscoveryProtocol>{},
    this.firstSeenAt,
    this.lastSeenAt,
    this.advertisedTtl,
    this.confidence = 0.0,
    this.protocolMetadata = const <String, Object?>{},
    this.metadata = const <String, Object?>{},
  });

  /// A stable identifier for this device.
  final String id;

  /// A human-readable display name for this device.
  final String displayName;

  /// The hostname of this device, if known.
  final String? hostname;

  /// The addresses associated with this device.
  final List<InternetAddressValue> addresses;

  /// The network interfaces through which this device was observed.
  final List<LocalNetworkInterface> interfaces;

  /// The services discovered on this device.
  final List<LocalService> services;

  /// The classified type of this device.
  final LocalDeviceType type;

  /// The inferred capabilities of this device.
  final Set<LocalDeviceCapability> capabilities;

  /// Evidence used to infer this device's capabilities and type.
  final List<CapabilityEvidence> capabilityEvidence;

  /// Identity information for this device.
  final LocalDeviceIdentity identity;

  /// Vendor information for this device.
  final LocalDeviceVendor? vendor;

  /// The reachability status of this device.
  final LocalDeviceReachability reachability;

  /// The protocols that discovered this device.
  final Set<LocalDiscoveryProtocol> discoveredBy;

  /// When this device was first seen.
  final DateTime? firstSeenAt;

  /// When this device was last seen.
  final DateTime? lastSeenAt;

  /// The advertised TTL of this device.
  final Duration? advertisedTtl;

  /// A confidence score (0.0 to 1.0) for the device classification.
  final double confidence;

  /// Decoded IoT and smart home protocol metadata (Matter, HAP, Cast, AirPlay).
  final Map<String, Object?> protocolMetadata;

  /// Additional metadata about this device.
  final Map<String, Object?> metadata;

  /// Convenience getter for the hardware manufacturer name.
  String? get manufacturer => vendor?.name;

  /// Convenience getter for the device model name.
  String? get model => vendor?.model;

  /// Convenience getter for the model number.
  String? get modelNumber => vendor?.modelNumber;

  /// Returns the first IPv4 address, if any.
  InternetAddressValue? get ipv4Address {
    for (final address in addresses) {
      if (address.isIpv4) return address;
    }
    return null;
  }

  /// Returns the first IPv6 address, if any.
  InternetAddressValue? get ipv6Address {
    for (final address in addresses) {
      if (address.isIpv6) return address;
    }
    return null;
  }

  /// Returns all services of a given type.
  List<LocalService> servicesOfType(String serviceType) {
    return services.where((s) => s.serviceType == serviceType).toList();
  }

  /// Creates a copy of this device with the given fields replaced.
  LocalDevice copyWith({
    String? id,
    String? displayName,
    String? hostname,
    List<InternetAddressValue>? addresses,
    List<LocalNetworkInterface>? interfaces,
    List<LocalService>? services,
    LocalDeviceType? type,
    Set<LocalDeviceCapability>? capabilities,
    List<CapabilityEvidence>? capabilityEvidence,
    LocalDeviceIdentity? identity,
    LocalDeviceVendor? vendor,
    LocalDeviceReachability? reachability,
    Set<LocalDiscoveryProtocol>? discoveredBy,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
    Duration? advertisedTtl,
    double? confidence,
    Map<String, Object?>? protocolMetadata,
    Map<String, Object?>? metadata,
  }) {
    return LocalDevice(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      hostname: hostname ?? this.hostname,
      addresses: addresses ?? this.addresses,
      interfaces: interfaces ?? this.interfaces,
      services: services ?? this.services,
      type: type ?? this.type,
      capabilities: capabilities ?? this.capabilities,
      capabilityEvidence: capabilityEvidence ?? this.capabilityEvidence,
      identity: identity ?? this.identity,
      vendor: vendor ?? this.vendor,
      reachability: reachability ?? this.reachability,
      discoveredBy: discoveredBy ?? this.discoveredBy,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      advertisedTtl: advertisedTtl ?? this.advertisedTtl,
      confidence: confidence ?? this.confidence,
      protocolMetadata: protocolMetadata ?? this.protocolMetadata,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocalDevice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LocalDevice('
        'id: $id, '
        'displayName: $displayName, '
        'type: $type, '
        'addresses: $addresses)';
  }
}

/// Vendor information for a discovered device.
class LocalDeviceVendor {
  const LocalDeviceVendor({
    this.name,
    this.url,
    this.model,
    this.modelNumber,
    this.serialNumber,
  });

  /// The vendor name.
  final String? name;

  /// The vendor's website URL.
  final Uri? url;

  /// The device model name.
  final String? model;

  /// The device model number.
  final String? modelNumber;

  /// The device serial number.
  final String? serialNumber;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocalDeviceVendor &&
        other.name == name &&
        other.url == url &&
        other.model == model &&
        other.modelNumber == modelNumber &&
        other.serialNumber == serialNumber;
  }

  @override
  int get hashCode => Object.hash(name, url, model, modelNumber, serialNumber);
}

/// The reachability status of a device.
enum LocalReachabilityStatus {
  /// Reachability has not been checked.
  unknown,

  /// The device is reachable.
  reachable,

  /// The device is partially reachable.
  partiallyReachable,

  /// The device is unreachable.
  unreachable,

  /// The reachability information is stale.
  stale,
}

/// Reachability information for a device.
class LocalDeviceReachability {
  const LocalDeviceReachability.unknown()
      : status = LocalReachabilityStatus.unknown,
        lastCheckedAt = null,
        latency = null,
        successfulAddress = null,
        successfulPort = null,
        methods = const {};

  const LocalDeviceReachability({
    required this.status,
    this.lastCheckedAt,
    this.latency,
    this.successfulAddress,
    this.successfulPort,
    this.methods = const {},
  });

  /// The reachability status.
  final LocalReachabilityStatus status;

  /// When reachability was last checked.
  final DateTime? lastCheckedAt;

  /// The measured latency, if available.
  final Duration? latency;

  /// The address that was successfully reached.
  final String? successfulAddress;

  /// The port that was successfully reached.
  final int? successfulPort;

  /// The methods used to determine reachability.
  final Set<LocalReachabilityMethod> methods;
}

/// The method used to determine reachability.
enum LocalReachabilityMethod {
  /// ICMP echo.
  icmp,

  /// TCP connect.
  tcpConnect,

  /// Service advertisement.
  serviceAdvertisement,

  /// Neighbor table.
  neighborTable,
}
