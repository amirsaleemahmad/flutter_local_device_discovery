/// Evidence that supports a device's inferred type or capabilities.
class CapabilityEvidence {
  const CapabilityEvidence({
    required this.capability,
    required this.source,
    required this.confidence,
    this.detail,
  });

  /// The capability this evidence supports.
  final String capability;

  /// The source of the evidence (e.g., 'service:_airplay._tcp', 'ssdp:urn:...').
  final String source;

  /// Confidence score from 0.0 to 1.0.
  final double confidence;

  /// Optional human-readable detail.
  final String? detail;

  /// Converts this evidence to a JSON-compatible map.
  Map<String, Object?> toMap() => <String, Object?>{
        'capability': capability,
        'source': source,
        'confidence': confidence,
        if (detail != null) 'detail': detail,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CapabilityEvidence &&
          other.capability == capability &&
          other.source == source &&
          other.confidence == confidence &&
          other.detail == detail;

  @override
  int get hashCode => Object.hash(capability, source, confidence, detail);

  @override
  String toString() =>
      'CapabilityEvidence($capability from $source, confidence: $confidence)';

  /// Converts this evidence to a JSON-compatible map.
  Map<String, Object?> toJson() => toMap();

  /// Creates a [CapabilityEvidence] from a JSON-compatible map.
  factory CapabilityEvidence.fromJson(Map<String, Object?> json) {
    return CapabilityEvidence(
      capability: json['capability'] as String,
      source: json['source'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      detail: json['detail'] as String?,
    );
  }
}
