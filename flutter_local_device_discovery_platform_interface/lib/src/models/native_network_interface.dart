import 'native_internet_address.dart';

/// A serializable network interface for platform channels.
class NativeNetworkInterface {
  const NativeNetworkInterface({
    required this.id,
    required this.name,
    this.displayName,
    required this.type,
    required this.addresses,
    this.isUp = false,
    this.isDefault = false,
    this.supportsMulticast = false,
    this.isMetered = false,
    this.isVpn = false,
    this.interfaceIndex,
    this.platformDetails = const <String, Object?>{},
  });

  final String id;
  final String name;
  final String? displayName;
  final int type;
  final List<NativeInternetAddress> addresses;
  final bool isUp;
  final bool isDefault;
  final bool supportsMulticast;
  final bool isMetered;
  final bool isVpn;
  final int? interfaceIndex;
  final Map<String, Object?> platformDetails;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'displayName': displayName,
      'type': type,
      'addresses': addresses.map((a) => a.toMap()).toList(),
      'isUp': isUp,
      'isDefault': isDefault,
      'supportsMulticast': supportsMulticast,
      'isMetered': isMetered,
      'isVpn': isVpn,
      'interfaceIndex': interfaceIndex,
      'platformDetails': platformDetails,
    };
  }

  static Map<String, Object?> _stringMap(Object? value) {
    if (value is Map<Object?, Object?>) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return const {};
  }

  static NativeNetworkInterface fromMap(Map<Object?, Object?> map) {
    final rawAddresses = map['addresses'] as List<Object?>? ?? const [];
    return NativeNetworkInterface(
      id: map['id']! as String,
      name: map['name']! as String,
      displayName: map['displayName'] as String?,
      type: map['type']! as int,
      addresses: rawAddresses
          .map(
            (a) => NativeInternetAddress.fromMap(a! as Map<Object?, Object?>),
          )
          .toList(),
      isUp: map['isUp'] as bool? ?? false,
      isDefault: map['isDefault'] as bool? ?? false,
      supportsMulticast: map['supportsMulticast'] as bool? ?? false,
      isMetered: map['isMetered'] as bool? ?? false,
      isVpn: map['isVpn'] as bool? ?? false,
      interfaceIndex: map['interfaceIndex'] as int?,
      platformDetails: _stringMap(map['platformDetails']),
    );
  }
}
