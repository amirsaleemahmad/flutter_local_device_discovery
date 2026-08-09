import 'dart:typed_data';

/// A serializable service registration request.
class NativeServiceRegistration {
  const NativeServiceRegistration({
    required this.instanceName,
    required this.serviceType,
    required this.port,
    this.txtRecords = const <String, Uint8List>{},
    this.host,
    this.interfaceNames = const <String>[],
  });

  final String instanceName;
  final String serviceType;
  final int port;
  final Map<String, Uint8List> txtRecords;
  final String? host;
  final List<String> interfaceNames;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'instanceName': instanceName,
      'serviceType': serviceType,
      'port': port,
      'txtRecords': txtRecords.map(
        (key, value) => MapEntry<String, Object?>(key, value),
      ),
      'host': host,
      'interfaceNames': interfaceNames,
    };
  }

  static NativeServiceRegistration fromMap(Map<Object?, Object?> map) {
    final rawTxt = map['txtRecords'] as Map<Object?, Object?>? ?? const {};
    final txtRecords = <String, Uint8List>{};
    rawTxt.forEach((key, value) {
      if (key is String && value is Uint8List) {
        txtRecords[key] = value;
      }
    });

    return NativeServiceRegistration(
      instanceName: map['instanceName']! as String,
      serviceType: map['serviceType']! as String,
      port: map['port']! as int,
      txtRecords: txtRecords,
      host: map['host'] as String?,
      interfaceNames: (map['interfaceNames'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }
}
