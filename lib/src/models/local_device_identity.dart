/// Identity information for a discovered device.
class LocalDeviceIdentity {
  const LocalDeviceIdentity({
    this.macAddress,
    this.serviceInstance,
    this.uniqueDeviceName,
    this.upnpUdn,
    this.wsEndpointReference,
    this.serialNumber,
    this.model,
    this.manufacturer,
    this.identifiers = const <String, String>{},
  });

  /// The MAC address of the device, if available.
  ///
  /// Modern platforms often restrict access to hardware addresses.
  final String? macAddress;

  /// The service instance name that identified this device.
  final String? serviceInstance;

  /// A unique device name from a discovery protocol.
  final String? uniqueDeviceName;

  /// The UPnP Unique Device Name (UDN).
  final String? upnpUdn;

  /// The WS-Discovery endpoint reference.
  final String? wsEndpointReference;

  /// The device serial number, if available.
  final String? serialNumber;

  /// The device model name.
  final String? model;

  /// The device manufacturer.
  final String? manufacturer;

  /// Additional protocol-specific identifiers.
  final Map<String, String> identifiers;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocalDeviceIdentity &&
        other.macAddress == macAddress &&
        other.serviceInstance == serviceInstance &&
        other.uniqueDeviceName == uniqueDeviceName &&
        other.upnpUdn == upnpUdn &&
        other.wsEndpointReference == wsEndpointReference &&
        other.serialNumber == serialNumber &&
        other.model == model &&
        other.manufacturer == manufacturer &&
        _mapEquals(other.identifiers, identifiers);
  }

  @override
  int get hashCode => Object.hash(
        macAddress,
        serviceInstance,
        uniqueDeviceName,
        upnpUdn,
        wsEndpointReference,
        serialNumber,
        model,
        manufacturer,
      );

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'LocalDeviceIdentity('
        'macAddress: $macAddress, '
        'serviceInstance: $serviceInstance, '
        'uniqueDeviceName: $uniqueDeviceName, '
        'upnpUdn: $upnpUdn, '
        'wsEndpointReference: $wsEndpointReference, '
        'serialNumber: $serialNumber, '
        'model: $model, '
        'manufacturer: $manufacturer)';
  }
}