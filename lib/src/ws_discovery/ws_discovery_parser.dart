import 'package:xml/xml.dart';

import '../models/metadata_security_policy.dart';
import '../models/ws_discovery_device.dart';

/// Parses WS-Discovery SOAP messages securely.
class WsDiscoveryParser {
  const WsDiscoveryParser();

  /// Parses an XML string representing a WS-Discovery SOAP message.
  ///
  /// Rejects document type definitions and external entities if specified
  /// in [policy], and restricts maximum nesting depth.
  List<WsDiscoveryDevice> parse(
    String xml, {
    String? sourceAddress,
    MetadataSecurityPolicy policy = MetadataSecurityPolicy.defaultPolicy,
  }) {
    if (xml.trim().isEmpty) {
      throw const FormatException('WS-Discovery XML is empty');
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
      throw FormatException('Invalid WS-Discovery XML: ${error.message}');
    }

    _validateDepth(document.rootElement, 1, policy.maxXmlNestingDepth);

    final results = <WsDiscoveryDevice>[];
    final root = document.rootElement;

    // Search for ProbeMatches, Hello, or Bye elements recursively by local name
    final probeMatchesList = _findDescendants(root, 'ProbeMatches');
    for (final pm in probeMatchesList) {
      final matches = _findDescendants(pm, 'ProbeMatch');
      for (final match in matches) {
        final device = _parseMatchHelloOrBye(match, sourceAddress);
        if (device != null) results.add(device);
      }
    }

    final helloList = _findDescendants(root, 'Hello');
    for (final hello in helloList) {
      final device = _parseMatchHelloOrBye(hello, sourceAddress);
      if (device != null) results.add(device);
    }

    final byeList = _findDescendants(root, 'Bye');
    for (final bye in byeList) {
      final device = _parseMatchHelloOrBye(bye, sourceAddress);
      if (device != null) results.add(device);
    }

    return results;
  }

  WsDiscoveryDevice? _parseMatchHelloOrBye(
    XmlElement element,
    String? sourceAddress,
  ) {
    final epr = _child(element, 'EndpointReference');
    if (epr == null) return null;
    final addr = _text(_child(epr, 'Address'));
    if (addr == null || addr.isEmpty) return null;

    final rawTypes = _text(_child(element, 'Types')) ?? '';
    final types = rawTypes
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    final rawScopes = _text(_child(element, 'Scopes')) ?? '';
    final scopes = rawScopes
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    final rawXAddrs = _text(_child(element, 'XAddrs')) ?? '';
    final xAddrs = rawXAddrs
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    final metaVerStr = _text(_child(element, 'MetadataVersion'));
    final metadataVersion =
        metaVerStr != null ? int.tryParse(metaVerStr) : null;

    return WsDiscoveryDevice(
      endpointReference: addr,
      types: types,
      scopes: scopes,
      xAddrs: xAddrs,
      metadataVersion: metadataVersion,
      sourceAddress: sourceAddress,
      lastSeenAt: DateTime.now(),
    );
  }

  void _validateDepth(XmlElement element, int depth, int maximum) {
    if (depth > maximum) {
      throw FormatException(
        'WS-Discovery XML exceeds nesting limit of $maximum',
      );
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

  List<XmlElement> _findDescendants(XmlElement parent, String localName) {
    final list = <XmlElement>[];
    void visit(XmlElement node) {
      if (node.name.local == localName) {
        list.add(node);
      }
      for (final child in node.childElements) {
        visit(child);
      }
    }

    visit(parent);
    return list;
  }

  String? _text(XmlElement? element) {
    final value = element?.innerText.trim();
    return value == null || value.isEmpty ? null : value;
  }
}
