/// A serializable service registration result.
class NativeServiceRegistrationResult {
  const NativeServiceRegistrationResult({
    required this.registrationId,
    required this.assignedName,
    required this.serviceType,
    required this.port,
  });

  final String registrationId;
  final String assignedName;
  final String serviceType;
  final int port;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'registrationId': registrationId,
      'assignedName': assignedName,
      'serviceType': serviceType,
      'port': port,
    };
  }

  static NativeServiceRegistrationResult fromMap(Map<Object?, Object?> map) {
    return NativeServiceRegistrationResult(
      registrationId: map['registrationId']! as String,
      assignedName: map['assignedName']! as String,
      serviceType: map['serviceType']! as String,
      port: map['port']! as int,
    );
  }
}