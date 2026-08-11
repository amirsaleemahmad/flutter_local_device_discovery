/// A device discovered via WS-Discovery (Web Services Dynamic Discovery).
class WsDiscoveryDevice {
  const WsDiscoveryDevice({
    required this.endpointReference,
    this.types = const <String>[],
    this.scopes = const <String>[],
    this.xAddrs = const <String>[],
    this.metadataVersion,
    this.sourceAddress,
    this.lastSeenAt,
  });

  /// The unique endpoint reference address (e.g. urn:uuid:...).
  final String endpointReference;

  /// The WS-Discovery types associated with the device.
  final List<String> types;

  /// The scopes associated with the device.
  final List<String> scopes;

  /// The list of transport addresses (XAddrs) where the service can be reached.
  final List<String> xAddrs;

  /// The metadata version of the device.
  final int? metadataVersion;

  /// The source IP address from which the response was received.
  final String? sourceAddress;

  /// When this device was most recently observed.
  final DateTime? lastSeenAt;

  /// Returns a copy of this device with updated fields.
  WsDiscoveryDevice copyWith({
    String? endpointReference,
    List<String>? types,
    List<String>? scopes,
    List<String>? xAddrs,
    int? metadataVersion,
    String? sourceAddress,
    DateTime? lastSeenAt,
  }) {
    return WsDiscoveryDevice(
      endpointReference: endpointReference ?? this.endpointReference,
      types: types ?? this.types,
      scopes: scopes ?? this.scopes,
      xAddrs: xAddrs ?? this.xAddrs,
      metadataVersion: metadataVersion ?? this.metadataVersion,
      sourceAddress: sourceAddress ?? this.sourceAddress,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WsDiscoveryDevice &&
          other.endpointReference == endpointReference;

  @override
  int get hashCode => endpointReference.hashCode;

  @override
  String toString() =>
      'WsDiscoveryDevice(endpoint: $endpointReference, types: $types, xAddrs: $xAddrs)';
}
