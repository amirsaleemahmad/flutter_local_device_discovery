/// A parsed UPnP device description document.
class UpnpDeviceDescription {
  const UpnpDeviceDescription({
    required this.udn,
    this.friendlyName,
    this.manufacturer,
    this.manufacturerUrl,
    this.modelDescription,
    this.modelName,
    this.modelNumber,
    this.modelUrl,
    this.serialNumber,
    this.deviceType,
    this.presentationUrl,
    this.icons = const [],
    this.services = const [],
    this.embeddedDevices = const [],
  });

  final String udn;
  final String? friendlyName;
  final String? manufacturer;
  final String? manufacturerUrl;
  final String? modelDescription;
  final String? modelName;
  final String? modelNumber;
  final String? modelUrl;
  final String? serialNumber;
  final String? deviceType;
  final String? presentationUrl;
  final List<UpnpIcon> icons;
  final List<UpnpService> services;
  final List<UpnpDeviceDescription> embeddedDevices;

  @override
  String toString() =>
      'UpnpDeviceDescription(udn: $udn, friendlyName: $friendlyName)';
}

class UpnpIcon {
  const UpnpIcon({
    required this.mimeType,
    required this.width,
    required this.height,
    this.depth,
    this.url,
  });

  final String mimeType;
  final int width;
  final int height;
  final int? depth;
  final String? url;

  @override
  String toString() => 'UpnpIcon(${width}x$height, $mimeType)';
}

class UpnpService {
  const UpnpService({
    required this.serviceType,
    required this.serviceId,
    this.controlUrl,
    this.eventSubUrl,
    this.scpdUrl,
  });

  final String serviceType;
  final String serviceId;
  final String? controlUrl;
  final String? eventSubUrl;
  final String? scpdUrl;

  @override
  String toString() => 'UpnpService(type: $serviceType, id: $serviceId)';
}
