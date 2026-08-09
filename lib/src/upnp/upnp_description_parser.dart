import 'package:xml/xml.dart';

import '../models/metadata_security_policy.dart';
import '../models/upnp_device_description.dart';

/// Parses UPnP device description XML into strongly typed models.
class UpnpDescriptionParser {
  const UpnpDescriptionParser();

  /// Parses [xml] and resolves relative URLs against [documentUri] or URLBase.
  ///
  /// The parser rejects document types/entities and excessive nesting according
  /// to [policy]. All network data should be treated as untrusted.
  UpnpDeviceDescription parse(
    String xml, {
    Uri? documentUri,
    MetadataSecurityPolicy policy = MetadataSecurityPolicy.defaultPolicy,
  }) {
    if (xml.trim().isEmpty) {
      throw const FormatException('UPnP description is empty');
    }
    if (policy.disableXmlExternalEntities) {
      final lowered = xml.toLowerCase();
      if (lowered.contains('<!doctype') || lowered.contains('<!entity')) {
        throw const FormatException(
          'Document types and XML entities are not allowed',
        );
      }
    }

    final XmlDocument document;
    try {
      document = XmlDocument.parse(xml);
    } on XmlParserException catch (error) {
      throw FormatException('Invalid UPnP XML: ${error.message}');
    }

    _validateDepth(document.rootElement, 1, policy.maxXmlNestingDepth);
    final root = document.rootElement;
    final declaredBase = _text(_child(root, 'URLBase'));
    final baseUri = declaredBase == null
        ? documentUri
        : Uri.tryParse(declaredBase)?.hasScheme == true
            ? Uri.parse(declaredBase)
            : documentUri?.resolve(declaredBase);
    final device = _child(root, 'device');
    if (device == null) {
      throw const FormatException('UPnP description has no root device');
    }
    return _parseDevice(device, baseUri);
  }

  UpnpDeviceDescription _parseDevice(XmlElement element, Uri? baseUri) {
    final udn = _text(_child(element, 'UDN'));
    if (udn == null || udn.isEmpty) {
      throw const FormatException('UPnP device is missing UDN');
    }

    final icons = <UpnpIcon>[];
    final iconList = _child(element, 'iconList');
    if (iconList != null) {
      for (final icon in _children(iconList, 'icon')) {
        final mimeType = _text(_child(icon, 'mimetype'));
        final width = int.tryParse(_text(_child(icon, 'width')) ?? '');
        final height = int.tryParse(_text(_child(icon, 'height')) ?? '');
        if (mimeType == null || width == null || height == null) continue;
        icons.add(
          UpnpIcon(
            mimeType: mimeType,
            width: width,
            height: height,
            depth: int.tryParse(_text(_child(icon, 'depth')) ?? ''),
            url: _resolve(_text(_child(icon, 'url')), baseUri),
          ),
        );
      }
    }

    final services = <UpnpService>[];
    final serviceList = _child(element, 'serviceList');
    if (serviceList != null) {
      for (final service in _children(serviceList, 'service')) {
        final type = _text(_child(service, 'serviceType'));
        final id = _text(_child(service, 'serviceId'));
        if (type == null || id == null) continue;
        services.add(
          UpnpService(
            serviceType: type,
            serviceId: id,
            controlUrl: _resolve(_text(_child(service, 'controlURL')), baseUri),
            eventSubUrl: _resolve(
              _text(_child(service, 'eventSubURL')),
              baseUri,
            ),
            scpdUrl: _resolve(_text(_child(service, 'SCPDURL')), baseUri),
          ),
        );
      }
    }

    final embeddedDevices = <UpnpDeviceDescription>[];
    final deviceList = _child(element, 'deviceList');
    if (deviceList != null) {
      for (final embedded in _children(deviceList, 'device')) {
        embeddedDevices.add(_parseDevice(embedded, baseUri));
      }
    }

    return UpnpDeviceDescription(
      udn: udn,
      friendlyName: _text(_child(element, 'friendlyName')),
      manufacturer: _text(_child(element, 'manufacturer')),
      manufacturerUrl: _resolve(
        _text(_child(element, 'manufacturerURL')),
        baseUri,
      ),
      modelDescription: _text(_child(element, 'modelDescription')),
      modelName: _text(_child(element, 'modelName')),
      modelNumber: _text(_child(element, 'modelNumber')),
      modelUrl: _resolve(_text(_child(element, 'modelURL')), baseUri),
      serialNumber: _text(_child(element, 'serialNumber')),
      deviceType: _text(_child(element, 'deviceType')),
      presentationUrl: _resolve(
        _text(_child(element, 'presentationURL')),
        baseUri,
      ),
      icons: List<UpnpIcon>.unmodifiable(icons),
      services: List<UpnpService>.unmodifiable(services),
      embeddedDevices: List<UpnpDeviceDescription>.unmodifiable(
        embeddedDevices,
      ),
    );
  }

  void _validateDepth(XmlElement element, int depth, int maximum) {
    if (depth > maximum) {
      throw FormatException('UPnP XML exceeds nesting limit of $maximum');
    }
    for (final child in element.childElements) {
      _validateDepth(child, depth + 1, maximum);
    }
  }

  XmlElement? _child(XmlElement parent, String localName) {
    for (final child in parent.childElements) {
      if (child.name.local == localName) return child;
    }
    return null;
  }

  Iterable<XmlElement> _children(XmlElement parent, String localName) {
    return parent.childElements.where((child) => child.name.local == localName);
  }

  String? _text(XmlElement? element) {
    final value = element?.innerText.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String? _resolve(String? value, Uri? baseUri) {
    if (value == null) return null;
    final uri = Uri.tryParse(value);
    if (uri == null) return value;
    if (uri.hasScheme || baseUri == null) return uri.toString();
    return baseUri.resolveUri(uri).toString();
  }
}
