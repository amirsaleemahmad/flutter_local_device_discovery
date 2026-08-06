import 'internet_address_value.dart';

/// The type of a network interface.
enum LocalInterfaceType {
  /// Unknown interface type.
  unknown,

  /// Wi-Fi interface.
  wifi,

  /// Ethernet interface.
  ethernet,

  /// VPN interface.
  vpn,

  /// Cellular interface.
  cellular,

  /// Loopback interface.
  loopback,

  /// Peer-to-peer interface (e.g., AirDrop).
  peerToPeer,

  /// Virtual interface.
  virtual,
}

/// A network interface on the local device.
class LocalNetworkInterface {
  const LocalNetworkInterface({
    required this.id,
    required this.name,
    this.displayName,
    this.type = LocalInterfaceType.unknown,
    this.addresses = const <InternetAddressValue>[],
    this.isUp = false,
    this.isDefault = false,
    this.supportsMulticast = false,
    this.isMetered = false,
    this.isVpn = false,
    this.interfaceIndex,
    this.platformDetails = const <String, Object?>{},
  });

  /// A stable identifier for this interface.
  final String id;

  /// The system name of the interface (e.g., `en0`, `eth0`).
  final String name;

  /// A human-readable display name, if available.
  final String? displayName;

  /// The type of this interface.
  final LocalInterfaceType type;

  /// The addresses assigned to this interface.
  final List<InternetAddressValue> addresses;

  /// Whether the interface is up.
  final bool isUp;

  /// Whether this is the default interface.
  final bool isDefault;

  /// Whether this interface supports multicast.
  final bool supportsMulticast;

  /// Whether this interface is metered.
  final bool isMetered;

  /// Whether this is a VPN interface.
  final bool isVpn;

  /// The platform-specific interface index.
  final int? interfaceIndex;

  /// Platform-specific details about this interface.
  final Map<String, Object?> platformDetails;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocalNetworkInterface &&
        other.id == id &&
        other.name == name &&
        other.displayName == displayName &&
        other.type == type &&
        _listEquals(other.addresses, addresses) &&
        other.isUp == isUp &&
        other.isDefault == isDefault &&
        other.supportsMulticast == supportsMulticast &&
        other.isMetered == isMetered &&
        other.isVpn == isVpn &&
        other.interfaceIndex == interfaceIndex;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        displayName,
        type,
        isUp,
        isDefault,
        supportsMulticast,
        isMetered,
        isVpn,
        interfaceIndex,
      );

  static bool _listEquals(
    List<InternetAddressValue> a,
    List<InternetAddressValue> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'LocalNetworkInterface('
        'id: $id, '
        'name: $name, '
        'type: $type, '
        'isUp: $isUp, '
        'isDefault: $isDefault)';
  }
}