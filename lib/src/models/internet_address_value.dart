/// A platform-independent representation of an internet address.
class InternetAddressValue {
  const InternetAddressValue({
    required this.address,
    required this.family,
    this.scopeId,
    this.interfaceName,
    this.isLoopback = false,
    this.isLinkLocal = false,
    this.isPrivate = false,
    this.isMulticast = false,
  });

  /// The textual representation of the address.
  final String address;

  /// The address family: 4 for IPv4, 6 for IPv6.
  final int family;

  /// The scope ID for IPv6 link-local addresses.
  final int? scopeId;

  /// The name of the network interface this address is associated with.
  final String? interfaceName;

  /// Whether this is a loopback address.
  final bool isLoopback;

  /// Whether this is a link-local address.
  final bool isLinkLocal;

  /// Whether this is a private (RFC 1918) address.
  final bool isPrivate;

  /// Whether this is a multicast address.
  final bool isMulticast;

  /// Whether this is an IPv4 address.
  bool get isIpv4 => family == 4;

  /// Whether this is an IPv6 address.
  bool get isIpv6 => family == 6;

  /// Parses an [InternetAddressValue] from a string.
  ///
  /// Throws a [FormatException] if the address is invalid.
  static InternetAddressValue parse(String address) {
    final value = tryParse(address);
    if (value == null) {
      throw FormatException('Invalid internet address: $address');
    }
    return value;
  }

  /// Attempts to parse an [InternetAddressValue] from a string.
  ///
  /// Returns `null` if the address is invalid.
  static InternetAddressValue? tryParse(String address) {
    if (address.isEmpty) return null;

    final isIpv6 = address.contains(':');
    final family = isIpv6 ? 6 : 4;

    // Basic validation
    if (isIpv6) {
      if (!RegExp(r'^[0-9a-fA-F:]+$').hasMatch(address)) return null;
    } else {
      final parts = address.split('.');
      if (parts.length != 4) return null;
      for (final part in parts) {
        final value = int.tryParse(part);
        if (value == null || value < 0 || value > 255) return null;
      }
    }

    return InternetAddressValue(
      address: address,
      family: family,
      isLoopback: _isLoopback(address, family),
      isLinkLocal: _isLinkLocal(address, family),
      isPrivate: _isPrivate(address, family),
      isMulticast: _isMulticast(address, family),
    );
  }

  static bool _isLoopback(String address, int family) {
    if (family == 4) return address == '127.0.0.1';
    return address == '::1';
  }

  static bool _isLinkLocal(String address, int family) {
    if (family == 4) {
      return address.startsWith('169.254.');
    }
    return address.toLowerCase().startsWith('fe80:');
  }

  static bool _isPrivate(String address, int family) {
    if (family == 4) {
      return address.startsWith('10.') ||
          address.startsWith('192.168.') ||
          (address.startsWith('172.') && _isPrivate172(address));
    }
    return address.toLowerCase().startsWith('fc') ||
        address.toLowerCase().startsWith('fd');
  }

  static bool _isPrivate172(String address) {
    final parts = address.split('.');
    if (parts.length < 2) return false;
    final second = int.tryParse(parts[1]);
    return second != null && second >= 16 && second <= 31;
  }

  static bool _isMulticast(String address, int family) {
    if (family == 4) {
      final parts = address.split('.');
      if (parts.isEmpty) return false;
      final first = int.tryParse(parts[0]);
      return first != null && first >= 224 && first <= 239;
    }
    return address.toLowerCase().startsWith('ff');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InternetAddressValue &&
        other.address == address &&
        other.family == family &&
        other.scopeId == scopeId &&
        other.interfaceName == interfaceName;
  }

  @override
  int get hashCode => Object.hash(address, family, scopeId, interfaceName);

  @override
  String toString() => address;

  /// Converts this value to a JSON-compatible map.
  Map<String, Object?> toJson() => {
        'address': address,
        'family': family,
        if (scopeId != null) 'scopeId': scopeId,
        if (interfaceName != null) 'interfaceName': interfaceName,
        'isLoopback': isLoopback,
        'isLinkLocal': isLinkLocal,
        'isPrivate': isPrivate,
        'isMulticast': isMulticast,
      };

  /// Creates an [InternetAddressValue] from a JSON-compatible map.
  factory InternetAddressValue.fromJson(Map<String, Object?> json) {
    return InternetAddressValue(
      address: json['address'] as String,
      family: json['family'] as int,
      scopeId: json['scopeId'] as int?,
      interfaceName: json['interfaceName'] as String?,
      isLoopback: json['isLoopback'] as bool? ?? false,
      isLinkLocal: json['isLinkLocal'] as bool? ?? false,
      isPrivate: json['isPrivate'] as bool? ?? false,
      isMulticast: json['isMulticast'] as bool? ?? false,
    );
  }
}
