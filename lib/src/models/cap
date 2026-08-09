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

  @override
  String toString() =>
      'CapabilityEvidence($capability from $source, confidence: $confidence)';
}