import '../models/capability_evidence.dart';
import '../models/internet_address_value.dart';
import '../models/local_device.dart';
import '../models/local_device_capability.dart';
import '../models/local_device_identity.dart';
import '../models/local_device_type.dart';
import '../models/local_network_interface.dart';
import '../models/local_service.dart';
import '../models/ssdp_device.dart';
import '../models/upnp_device_description.dart';
import 'local_discovery_protocol.dart';

/// Aggregates, enriches, classifies, and deduplicates protocol observations.
class DeviceAggregator {
  DeviceAggregator();

  /// Merges devices that share a UDN, hostname, address, or service instance.
  List<LocalDevice> aggregate(List<LocalDevice> devices) {
    final result = <LocalDevice>[];
    for (final rawDevice in devices) {
      final device = enrichFromServices(rawDevice);
      final index = result.indexWhere((existing) => _matches(existing, device));
      if (index < 0) {
        result.add(device);
      } else {
        result[index] = mergeDevices(result[index], device);
      }
    }
    return result;
  }

  /// Merges two observations already known to represent the same device.
  LocalDevice mergeDevices(LocalDevice a, LocalDevice b) {
    final addresses = <InternetAddressValue>{...a.addresses, ...b.addresses};
    final servicesById = <String, LocalService>{};
    for (final service in <LocalService>[...a.services, ...b.services]) {
      final existing = servicesById[service.id];
      if (existing == null || (!existing.resolved && service.resolved)) {
        servicesById[service.id] = service;
      }
    }
    final firstSeenAt = _earlier(a.firstSeenAt, b.firstSeenAt);
    final lastSeenAt = _later(a.lastSeenAt, b.lastSeenAt);
    final identity = _mergeIdentity(a.identity, b.identity);

    return enrichFromServices(
      LocalDevice(
        id: a.id,
        displayName: _preferredName(a.displayName, b.displayName),
        hostname: _preferredHostname(a.hostname, b.hostname),
        addresses: addresses.toList(growable: false),
        interfaces: <LocalNetworkInterface>{
          ...a.interfaces,
          ...b.interfaces,
        }.toList(growable: false),
        services: servicesById.values.toList(growable: false),
        type: a.type != LocalDeviceType.unknown ? a.type : b.type,
        capabilities: <LocalDeviceCapability>{
          ...a.capabilities,
          ...b.capabilities,
        },
        capabilityEvidence: <CapabilityEvidence>{
          ...a.capabilityEvidence,
          ...b.capabilityEvidence,
        }.toList(growable: false),
        identity: identity,
        vendor: a.vendor ?? b.vendor,
        reachability: a.reachability.status != LocalReachabilityStatus.unknown
            ? a.reachability
            : b.reachability,
        discoveredBy: <LocalDiscoveryProtocol>{
          ...a.discoveredBy,
          ...b.discoveredBy,
        },
        firstSeenAt: firstSeenAt,
        lastSeenAt: lastSeenAt,
        advertisedTtl: a.advertisedTtl ?? b.advertisedTtl,
        confidence: a.confidence > b.confidence ? a.confidence : b.confidence,
        metadata: <String, Object?>{...a.metadata, ...b.metadata},
      ),
    );
  }

  /// Merges an SSDP observation into a device or creates a new device.
  LocalDevice mergeSsdpDevice({
    required LocalDevice? existing,
    required SsdpDevice ssdp,
    required String discoveredBy,
  }) {
    final now = ssdp.lastSeenAt ?? DateTime.now();
    final rootUsn = ssdp.udn ?? ssdp.usn.split('::').first;
    final address = InternetAddressValue.tryParse(
      ssdp.sourceAddress ?? Uri.tryParse(ssdp.location)?.host ?? '',
    );
    final capabilities = _inferCapabilitiesFromSsdp(ssdp);
    final evidence = capabilities
        .map(
          (capability) => CapabilityEvidence(
            capability: capability.name,
            source: '$discoveredBy:${ssdp.searchTarget}',
            confidence: 0.75,
          ),
        )
        .toList();
    final observation = LocalDevice(
      id: rootUsn,
      displayName: ssdp.friendlyName ?? _ssdpDisplayName(ssdp),
      hostname: Uri.tryParse(ssdp.location)?.host,
      addresses: address == null ? const [] : <InternetAddressValue>[address],
      type: _inferTypeFromSsdp(ssdp),
      capabilities: <LocalDeviceCapability>{
        LocalDeviceCapability.upnp,
        ...capabilities,
      },
      capabilityEvidence: <CapabilityEvidence>[
        CapabilityEvidence(
          capability: LocalDeviceCapability.upnp.name,
          source: '$discoveredBy:${ssdp.searchTarget}',
          confidence: 1,
        ),
        ...evidence,
      ],
      identity: LocalDeviceIdentity(
        uniqueDeviceName: ssdp.usn,
        upnpUdn: rootUsn,
        model: ssdp.modelName,
        manufacturer: ssdp.manufacturer,
        identifiers: <String, String>{
          'ssdpUsn': ssdp.usn,
          if (ssdp.bootId != null) 'upnpBootId': ssdp.bootId!,
          if (ssdp.configId != null) 'upnpConfigId': ssdp.configId!,
        },
      ),
      discoveredBy: const <LocalDiscoveryProtocol>{LocalDiscoveryProtocol.ssdp},
      firstSeenAt: existing?.firstSeenAt ?? now,
      lastSeenAt: now,
      advertisedTtl: ssdp.cacheControlMaxAge == null
          ? null
          : Duration(seconds: ssdp.cacheControlMaxAge!),
      confidence: 0.75,
      metadata: <String, Object?>{
        'ssdpLocation': ssdp.location,
        'ssdpUsn': ssdp.usn,
        'ssdpSearchTarget': ssdp.searchTarget,
        if (ssdp.server != null) 'ssdpServer': ssdp.server,
        if (ssdp.sourceAddress != null) 'ssdpSourceAddress': ssdp.sourceAddress,
        if (ssdp.bootId != null) 'upnpBootId': ssdp.bootId,
        if (ssdp.configId != null) 'upnpConfigId': ssdp.configId,
        if (ssdp.headers.isNotEmpty) 'ssdpHeaders': ssdp.headers,
      },
    );
    if (existing == null) return observation;
    final merged = mergeDevices(existing, observation);
    return ssdp.friendlyName == null
        ? merged
        : merged.copyWith(displayName: ssdp.friendlyName);
  }

  /// Enriches a device using a parsed UPnP description document.
  LocalDevice enrichWithUpnp({
    required LocalDevice device,
    required UpnpDeviceDescription description,
  }) {
    final inferred = _inferCapabilitiesFromUpnp(description);
    final evidence = inferred
        .map(
          (capability) => CapabilityEvidence(
            capability: capability.name,
            source: 'upnp:${description.deviceType ?? description.udn}',
            confidence: 0.9,
            detail: description.services
                .where(
                  (service) =>
                      _capabilitiesForUpnpService(service).contains(capability),
                )
                .map((service) => service.serviceType)
                .join(', '),
          ),
        )
        .toList();
    return device.copyWith(
      displayName: description.friendlyName ?? device.displayName,
      type: _inferTypeFromUpnp(description, device.type),
      capabilities: <LocalDeviceCapability>{
        ...device.capabilities,
        LocalDeviceCapability.upnp,
        ...inferred,
      },
      capabilityEvidence: <CapabilityEvidence>{
        ...device.capabilityEvidence,
        const CapabilityEvidence(
          capability: 'upnp',
          source: 'upnp:device-description',
          confidence: 1,
        ),
        ...evidence,
      }.toList(growable: false),
      identity: _mergeIdentity(
        device.identity,
        LocalDeviceIdentity(
          upnpUdn: description.udn,
          uniqueDeviceName: description.udn,
          serialNumber: description.serialNumber,
          model: description.modelName,
          manufacturer: description.manufacturer,
        ),
      ),
      discoveredBy: <LocalDiscoveryProtocol>{
        ...device.discoveredBy,
        LocalDiscoveryProtocol.upnp,
      },
      confidence: device.confidence > 0.9 ? device.confidence : 0.9,
      metadata: <String, Object?>{
        ...device.metadata,
        'upnpUdn': description.udn,
        if (description.manufacturer != null)
          'manufacturer': description.manufacturer,
        if (description.manufacturerUrl != null)
          'manufacturerUrl': description.manufacturerUrl,
        if (description.modelName != null) 'modelName': description.modelName,
        if (description.modelNumber != null)
          'modelNumber': description.modelNumber,
        if (description.serialNumber != null)
          'serialNumber': description.serialNumber,
        if (description.deviceType != null)
          'upnpDeviceType': description.deviceType,
        if (description.presentationUrl != null)
          'presentationUrl': description.presentationUrl,
        'upnpServices': description.services
            .map((service) => service.serviceType)
            .toList(growable: false),
        'upnpEmbeddedDeviceCount': description.embeddedDevices.length,
        'upnpIconCount': description.icons.length,
      },
      lastSeenAt: DateTime.now(),
    );
  }

  /// Infers device type and capabilities from DNS-SD service types.
  LocalDevice enrichFromServices(LocalDevice device) {
    var type = device.type;
    var confidence = device.confidence;
    final capabilities = <LocalDeviceCapability>{...device.capabilities};
    final evidence = <CapabilityEvidence>{...device.capabilityEvidence};
    for (final service in device.services) {
      final inference = _serviceInference(service.serviceType);
      capabilities.addAll(inference.capabilities);
      if (type == LocalDeviceType.unknown &&
          inference.type != LocalDeviceType.unknown) {
        type = inference.type;
        confidence = confidence > inference.confidence
            ? confidence
            : inference.confidence;
      }
      for (final capability in inference.capabilities) {
        evidence.add(
          CapabilityEvidence(
            capability: capability.name,
            source: 'service:${service.serviceType}',
            confidence: inference.confidence,
          ),
        );
      }
    }
    return device.copyWith(
      type: type,
      capabilities: capabilities,
      capabilityEvidence: evidence.toList(growable: false),
      confidence: confidence,
    );
  }

  bool _matches(LocalDevice a, LocalDevice b) {
    final aUdn = _udn(a);
    final bUdn = _udn(b);
    if (aUdn != null && bUdn != null && aUdn == bUdn) return true;

    final aHost = _normalizeHostname(a.hostname);
    final bHost = _normalizeHostname(b.hostname);
    if (aHost != null && bHost != null && aHost == bHost) return true;

    final aAddresses = a.addresses.map((address) => address.address).toSet();
    if (aAddresses.isNotEmpty &&
        b.addresses.any((address) => aAddresses.contains(address.address))) {
      return true;
    }

    final aInstances = <String>{
      if (a.identity.serviceInstance != null)
        a.identity.serviceInstance!.toLowerCase(),
      ...a.services.map((service) => service.instanceName.toLowerCase()),
    };
    return aInstances.isNotEmpty &&
        <String>{
          if (b.identity.serviceInstance != null)
            b.identity.serviceInstance!.toLowerCase(),
          ...b.services.map((service) => service.instanceName.toLowerCase()),
        }.any(aInstances.contains);
  }

  String? _udn(LocalDevice device) {
    final value = device.identity.upnpUdn ??
        device.metadata['upnpUdn'] as String? ??
        device.metadata['udn'] as String? ??
        device.metadata['ssdpUsn'] as String?;
    return value?.split('::').first.trim().toLowerCase();
  }

  String? _normalizeHostname(String? hostname) {
    if (hostname == null || hostname.trim().isEmpty) return null;
    return hostname.trim().toLowerCase().replaceFirst(RegExp(r'\.$'), '');
  }

  LocalDeviceIdentity _mergeIdentity(
    LocalDeviceIdentity a,
    LocalDeviceIdentity b,
  ) {
    return LocalDeviceIdentity(
      macAddress: a.macAddress ?? b.macAddress,
      serviceInstance: a.serviceInstance ?? b.serviceInstance,
      uniqueDeviceName: a.uniqueDeviceName ?? b.uniqueDeviceName,
      upnpUdn: a.upnpUdn ?? b.upnpUdn,
      wsEndpointReference: a.wsEndpointReference ?? b.wsEndpointReference,
      serialNumber: a.serialNumber ?? b.serialNumber,
      model: a.model ?? b.model,
      manufacturer: a.manufacturer ?? b.manufacturer,
      identifiers: <String, String>{...a.identifiers, ...b.identifiers},
    );
  }

  String _preferredName(String a, String b) {
    if (a.trim().isEmpty) return b;
    if (b.trim().isEmpty) return a;
    final aLooksTechnical = a.startsWith('uuid:') || a.contains('urn:');
    final bLooksTechnical = b.startsWith('uuid:') || b.contains('urn:');
    return aLooksTechnical && !bLooksTechnical ? b : a;
  }

  String? _preferredHostname(String? a, String? b) {
    if (a == null || a.isEmpty) return b;
    if (b == null || b.isEmpty) return a;
    final aIsAddress = InternetAddressValue.tryParse(a) != null;
    final bIsAddress = InternetAddressValue.tryParse(b) != null;
    final aIsLocalName = a.toLowerCase().endsWith('.local') ||
        a.toLowerCase().endsWith('.local.');
    final bIsLocalName = b.toLowerCase().endsWith('.local') ||
        b.toLowerCase().endsWith('.local.');
    if (!aIsLocalName && bIsLocalName) return b;
    return aIsAddress && !bIsAddress ? b : a;
  }

  DateTime? _earlier(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }

  DateTime? _later(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  String _ssdpDisplayName(SsdpDevice device) {
    final target = device.searchTarget.split(':');
    if (target.length >= 4) return target[target.length - 2];
    return device.usn.split('::').first;
  }

  LocalDeviceType _inferTypeFromSsdp(SsdpDevice ssdp) {
    final value = '${ssdp.searchTarget} ${ssdp.deviceType ?? ''}'.toLowerCase();
    if (value.contains('mediarenderer')) return LocalDeviceType.mediaRenderer;
    if (value.contains('mediaserver')) return LocalDeviceType.mediaServer;
    if (value.contains('internetgatewaydevice')) return LocalDeviceType.gateway;
    if (value.contains('router')) return LocalDeviceType.router;
    if (value.contains('printer')) return LocalDeviceType.printer;
    if (value.contains('camera') || value.contains('onvif')) {
      return LocalDeviceType.camera;
    }
    return LocalDeviceType.unknown;
  }

  Set<LocalDeviceCapability> _inferCapabilitiesFromSsdp(SsdpDevice ssdp) {
    final value = '${ssdp.searchTarget} ${ssdp.deviceType ?? ''}'.toLowerCase();
    return <LocalDeviceCapability>{
      if (value.contains('mediarenderer')) ...<LocalDeviceCapability>{
        LocalDeviceCapability.mediaPlayback,
        LocalDeviceCapability.streaming,
        LocalDeviceCapability.dlna,
      },
      if (value.contains('mediaserver')) ...<LocalDeviceCapability>{
        LocalDeviceCapability.fileSharing,
        LocalDeviceCapability.dlna,
      },
      if (value.contains('printer')) LocalDeviceCapability.printing,
      if (value.contains('internetgateway')) LocalDeviceCapability.routing,
      if (value.contains('camera') || value.contains('onvif'))
        LocalDeviceCapability.onvif,
    };
  }

  LocalDeviceType _inferTypeFromUpnp(
    UpnpDeviceDescription description,
    LocalDeviceType current,
  ) {
    if (current != LocalDeviceType.unknown) return current;
    final value = description.deviceType?.toLowerCase() ?? '';
    if (value.contains('mediarenderer')) return LocalDeviceType.mediaRenderer;
    if (value.contains('mediaserver')) return LocalDeviceType.mediaServer;
    if (value.contains('internetgateway')) return LocalDeviceType.gateway;
    if (value.contains('printer')) return LocalDeviceType.printer;
    if (value.contains('camera')) return LocalDeviceType.camera;
    return LocalDeviceType.unknown;
  }

  Set<LocalDeviceCapability> _inferCapabilitiesFromUpnp(
    UpnpDeviceDescription description,
  ) {
    return description.services.expand(_capabilitiesForUpnpService).toSet();
  }

  Set<LocalDeviceCapability> _capabilitiesForUpnpService(UpnpService service) {
    final value = service.serviceType.toLowerCase();
    return <LocalDeviceCapability>{
      if (value.contains('renderingcontrol') ||
          value.contains('avtransport')) ...<LocalDeviceCapability>{
        LocalDeviceCapability.mediaPlayback,
        LocalDeviceCapability.streaming,
        LocalDeviceCapability.dlna,
      },
      if (value.contains('contentdirectory')) LocalDeviceCapability.fileSharing,
      if (value.contains('print')) LocalDeviceCapability.printing,
      if (value.contains('wanipconnection') ||
          value.contains('wanpppconnection'))
        LocalDeviceCapability.routing,
    };
  }

  _ServiceInference _serviceInference(String serviceType) {
    final value = serviceType.toLowerCase();
    if (value.contains('_ipp') ||
        value.contains('_printer') ||
        value.contains('_pdl-datastream')) {
      return const _ServiceInference(
        LocalDeviceType.printer,
        <LocalDeviceCapability>{LocalDeviceCapability.printing},
        0.9,
      );
    }
    if (value.contains('_scanner')) {
      return const _ServiceInference(
        LocalDeviceType.scanner,
        <LocalDeviceCapability>{LocalDeviceCapability.scanning},
        0.9,
      );
    }
    if (value.contains('_airplay') || value.contains('_raop')) {
      return const _ServiceInference(
        LocalDeviceType.mediaRenderer,
        <LocalDeviceCapability>{
          LocalDeviceCapability.airPlay,
          LocalDeviceCapability.streaming,
        },
        0.85,
      );
    }
    if (value.contains('_googlecast')) {
      return const _ServiceInference(
        LocalDeviceType.mediaRenderer,
        <LocalDeviceCapability>{
          LocalDeviceCapability.cast,
          LocalDeviceCapability.streaming,
        },
        0.85,
      );
    }
    if (value.contains('_smb') ||
        value.contains('_nfs') ||
        value.contains('_afpovertcp')) {
      return const _ServiceInference(
        LocalDeviceType.nas,
        <LocalDeviceCapability>{
          LocalDeviceCapability.fileSharing,
          LocalDeviceCapability.smb,
        },
        0.8,
      );
    }
    if (value.contains('_https')) {
      return const _ServiceInference(
        LocalDeviceType.webServer,
        <LocalDeviceCapability>{LocalDeviceCapability.https},
        0.65,
      );
    }
    if (value.contains('_http')) {
      return const _ServiceInference(
        LocalDeviceType.webServer,
        <LocalDeviceCapability>{LocalDeviceCapability.http},
        0.65,
      );
    }
    if (value.contains('_ssh')) {
      return const _ServiceInference(
        LocalDeviceType.server,
        <LocalDeviceCapability>{LocalDeviceCapability.ssh},
        0.7,
      );
    }
    if (value.contains('_homekit') || value.contains('_hap')) {
      return const _ServiceInference(
        LocalDeviceType.smartHomeHub,
        <LocalDeviceCapability>{LocalDeviceCapability.smartHome},
        0.75,
      );
    }
    if (value.contains('_workstation')) {
      return const _ServiceInference(
        LocalDeviceType.computer,
        <LocalDeviceCapability>{},
        0.7,
      );
    }
    return const _ServiceInference(
      LocalDeviceType.unknown,
      <LocalDeviceCapability>{},
      0,
    );
  }
}

class _ServiceInference {
  const _ServiceInference(this.type, this.capabilities, this.confidence);

  final LocalDeviceType type;
  final Set<LocalDeviceCapability> capabilities;
  final double confidence;
}
