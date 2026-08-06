/// A serializable representation of an internet address for platform channels.
class NativeInternetAddress {
  const NativeInternetAddress({
    required this.address,
    required this.family,
    this.scopeId,
    this.interfaceName,
    this.isLoopback = false,
    this.isLinkLocal = false,
    this.isPrivate = false,
    this.isMulticast = false,
  });

  final String address;
  final int family;
  final int? scopeId;
  final String? interfaceName;
  final bool isLoopback;
  final bool isLinkLocal;
  final bool isPrivate;
  final bool isMulticast;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'address': address,
      'family': family,
      'scopeId': scopeId,
      'interfaceName': interfaceName,
      'isLoopback': isLoopback,
      'isLinkLocal': isLinkLocal,
      'isPrivate': isPrivate,
      'isMulticast': isMulticast,
    };
  }

  static NativeInternetAddress fromMap(Map<Object?, Object?> map) {
    return NativeInternetAddress(
      address: map['address']! as String,
      family: map['family']! as int,
      scopeId: map['scopeId'] as int?,
      interfaceName: map['interfaceName'] as String?,
      isLoopback: map['isLoopback'] as bool? ?? false,
      isLinkLocal: map['isLinkLocal'] as bool? ?? false,
      isPrivate: map['isPrivate'] as bool? ?? false,
      isMulticast: map['isMulticast'] as bool? ?? false,
    );
  }
}