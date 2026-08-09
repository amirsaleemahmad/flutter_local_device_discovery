/// Validates service type strings.
abstract final class ServiceTypeValidator {
  /// Validates a service type string (e.g., `_http._tcp`).
  ///
  /// Returns `true` if the service type is valid.
  static bool isValid(String serviceType) {
    if (serviceType.isEmpty) return false;
    if (serviceType.length > 255) return false;

    // Must start with underscore for the service name part.
    final parts = serviceType.split('.');
    if (parts.length < 2) return false;

    // First part must be _service
    if (!parts[0].startsWith('_')) return false;
    if (parts[0].length < 2) return false;

    // Last part must be _tcp or _udp
    final transport = parts[parts.length - 1];
    if (transport != '_tcp' && transport != '_udp') return false;

    // Validate each part
    for (final part in parts) {
      if (part.isEmpty) return false;
      if (part.length > 63) return false;
      // Allow letters, digits, hyphens, and underscores
      for (final char in part.codeUnits) {
        final isLetter =
            (char >= 65 && char <= 90) || (char >= 97 && char <= 122);
        final isDigit = char >= 48 && char <= 57;
        final isHyphen = char == 45;
        final isUnderscore = char == 95;
        if (!isLetter && !isDigit && !isHyphen && !isUnderscore) {
          return false;
        }
      }
    }

    return true;
  }

  /// Parses a service type string into its components.
  ///
  /// Returns `null` if the service type is invalid.
  static ServiceTypeParts? tryParse(String serviceType) {
    if (!isValid(serviceType)) return null;
    final parts = serviceType.split('.');
    return ServiceTypeParts(
      serviceName: parts[0].substring(1),
      transport: parts[parts.length - 1].substring(1),
      subTypes:
          parts.length > 2 ? parts.sublist(1, parts.length - 1) : const [],
    );
  }
}

/// The parsed components of a service type.
class ServiceTypeParts {
  const ServiceTypeParts({
    required this.serviceName,
    required this.transport,
    this.subTypes = const <String>[],
  });

  /// The service name without the leading underscore (e.g., `http`).
  final String serviceName;

  /// The transport protocol (`tcp` or `udp`).
  final String transport;

  /// Any sub-types (e.g., `_printer` in `_ipp._printer._tcp`).
  final List<String> subTypes;

  /// The full service type string.
  String get fullType {
    final buffer = StringBuffer('_$serviceName');
    for (final subType in subTypes) {
      buffer.write('._$subType');
    }
    buffer.write('._$transport');
    return buffer.toString();
  }
}
