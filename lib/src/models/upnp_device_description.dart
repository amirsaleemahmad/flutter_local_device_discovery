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

  /// Converts this description to a JSON-compatible map.
  Map<String, Object?> toJson() => {
        'udn': udn,
        if (friendlyName != null) 'friendlyName': friendlyName,
        if (manufacturer != null) 'manufacturer': manufacturer,
        if (manufacturerUrl != null) 'manufacturerUrl': manufacturerUrl,
        if (modelDescription != null) 'modelDescription': modelDescription,
        if (modelName != null) 'modelName': modelName,
        if (modelNumber != null) 'modelNumber': modelNumber,
        if (modelUrl != null) 'modelUrl': modelUrl,
        if (serialNumber != null) 'serialNumber': serialNumber,
        if (deviceType != null) 'deviceType': deviceType,
        if (presentationUrl != null) 'presentationUrl': presentationUrl,
        'icons': icons.map((e) => e.toJson()).toList(),
        'services': services.map((e) => e.toJson()).toList(),
        'embeddedDevices': embeddedDevices.map((e) => e.toJson()).toList(),
      };

  /// Creates a [UpnpDeviceDescription] from a JSON-compatible map.
  factory UpnpDeviceDescription.fromJson(Map<String, Object?> json) {
    return UpnpDeviceDescription(
      udn: json['udn'] as String,
      friendlyName: json['friendlyName'] as String?,
      manufacturer: json['manufacturer'] as String?,
      manufacturerUrl: json['manufacturerUrl'] as String?,
      modelDescription: json['modelDescription'] as String?,
      modelName: json['modelName'] as String?,
      modelNumber: json['modelNumber'] as String?,
      modelUrl: json['modelUrl'] as String?,
      serialNumber: json['serialNumber'] as String?,
      deviceType: json['deviceType'] as String?,
      presentationUrl: json['presentationUrl'] as String?,
      icons: (json['icons'] as List<dynamic>?)
              ?.map((e) => UpnpIcon.fromJson(e as Map<String, Object?>))
              .toList() ??
          const [],
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => UpnpService.fromJson(e as Map<String, Object?>))
              .toList() ??
          const [],
      embeddedDevices: (json['embeddedDevices'] as List<dynamic>?)
              ?.map((e) => UpnpDeviceDescription.fromJson(e as Map<String, Object?>))
              .toList() ??
          const [],
    );
  }
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

  /// Converts this icon to a JSON-compatible map.
  Map<String, Object?> toJson() => {
        'mimeType': mimeType,
        'width': width,
        'height': height,
        if (depth != null) 'depth': depth,
        if (url != null) 'url': url,
      };

  /// Creates an [UpnpIcon] from a JSON-compatible map.
  factory UpnpIcon.fromJson(Map<String, Object?> json) {
    return UpnpIcon(
      mimeType: json['mimeType'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      depth: json['depth'] as int?,
      url: json['url'] as String?,
    );
  }
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

  /// Converts this service to a JSON-compatible map.
  Map<String, Object?> toJson() => {
        'serviceType': serviceType,
        'serviceId': serviceId,
        if (controlUrl != null) 'controlUrl': controlUrl,
        if (eventSubUrl != null) 'eventSubUrl': eventSubUrl,
        if (scpdUrl != null) 'scpdUrl': scpdUrl,
      };

  /// Creates an [UpnpService] from a JSON-compatible map.
  factory UpnpService.fromJson(Map<String, Object?> json) {
    return UpnpService(
      serviceType: json['serviceType'] as String,
      serviceId: json['serviceId'] as String,
      controlUrl: json['controlUrl'] as String?,
      eventSubUrl: json['eventSubUrl'] as String?,
      scpdUrl: json['scpdUrl'] as String?,
    );
  }
}
