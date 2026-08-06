/// Serializable readiness report from a native platform.
class NativeDiscoveryReadiness {
  const NativeDiscoveryReadiness({
    this.canStart = false,
    this.requirements = const <String>[],
    this.warnings = const <String>[],
    this.platformDetails = const <String, Object?>{},
  });

  final bool canStart;
  final List<String> requirements;
  final List<String> warnings;
  final Map<String, Object?> platformDetails;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'canStart': canStart,
      'requirements': requirements,
      'warnings': warnings,
      'platformDetails': platformDetails,
    };
  }

  static Map<String, Object?> _stringMap(Object? value) {
    if (value is Map<Object?, Object?>) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return const {};
  }


  static NativeDiscoveryReadiness fromMap(Map<Object?, Object?> map) {
    return NativeDiscoveryReadiness(
      canStart: map['canStart'] as bool? ?? false,
      requirements: (map['requirements'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(),
      warnings: (map['warnings'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(),
      platformDetails: _stringMap(map['platformDetails']),
    );
  }
}