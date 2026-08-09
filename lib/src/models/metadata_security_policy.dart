/// Security policies for metadata fetching (UPnP descriptions, etc.).
class MetadataSecurityPolicy {
  const MetadataSecurityPolicy({
    this.maxRedirects = 3,
    this.maxResponseSizeBytes = 256 * 1024,
    this.timeoutDuration = const Duration(seconds: 5),
    this.allowExternalAddresses = false,
    this.disableXmlExternalEntities = true,
    this.maxXmlNestingDepth = 50,
  });

  /// Maximum number of HTTP redirects to follow.
  final int maxRedirects;

  /// Maximum response body size in bytes.
  final int maxResponseSizeBytes;

  /// Timeout for the HTTP request.
  final Duration timeoutDuration;

  /// Whether to allow fetching from non-local-network addresses.
  /// Defaults to false for security.
  final bool allowExternalAddresses;

  /// Whether to disable XML external entity (XXE) processing.
  /// Defaults to true for security.
  final bool disableXmlExternalEntities;

  /// Maximum XML element nesting depth to prevent DoS.
  final int maxXmlNestingDepth;

  /// Default security policy.
  static const MetadataSecurityPolicy defaultPolicy =
      MetadataSecurityPolicy();

  @override
  String toString() =>
      'MetadataSecurityPolicy(maxRedirects: $maxRedirects, '
      'maxSize: ${maxResponseSizeBytes}B, timeout: ${timeoutDuration.inSeconds}s, '
      'allowExternal: $allowExternalAddresses)';
}