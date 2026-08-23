/// The status of discovery-related permissions.
class DiscoveryPermissions {
  const DiscoveryPermissions({
    this.localNetwork = PermissionStatus.unknown,
    this.location = PermissionStatus.unknown,
    this.bluetooth = PermissionStatus.unknown,
    this.notifications = PermissionStatus.unknown,
    this.missingManifestPermissions = const <String>[],
    this.missingInfoPlistKeys = const <String>[],
    this.platformDetails = const <String, Object?>{},
  });

  /// Local network permission status (iOS/macOS).
  final PermissionStatus localNetwork;

  /// Location permission status (needed for Wi-Fi info on Android).
  final PermissionStatus location;

  /// Bluetooth permission status (needed for BLE scanning).
  final PermissionStatus bluetooth;

  /// Notification permission status (needed for background monitoring on Android 13+).
  final PermissionStatus notifications;

  /// Android-specific: manifest permissions that are missing.
  final List<String> missingManifestPermissions;

  /// iOS-specific: Info.plist keys that are missing.
  final List<String> missingInfoPlistKeys;

  /// Additional platform-specific details.
  final Map<String, Object?> platformDetails;

  /// Creates a [DiscoveryPermissions] from a JSON map.
  factory DiscoveryPermissions.fromJson(Map<String, Object?> json) {
    return DiscoveryPermissions(
      localNetwork: _parseStatus(json['localNetwork']),
      location: _parseStatus(json['location']),
      bluetooth: _parseStatus(json['bluetooth']),
      notifications: _parseStatus(json['notifications']),
      missingManifestPermissions: (json['missingManifestPermissions'] as List<dynamic>?)?.cast<String>() ?? const <String>[],
      missingInfoPlistKeys: (json['missingInfoPlistKeys'] as List<dynamic>?)?.cast<String>() ?? const <String>[],
      platformDetails: (json['platformDetails'] as Map<String, dynamic>?)?.cast<String, Object?>() ?? const <String, Object?>{},
    );
  }

  /// Converts this [DiscoveryPermissions] to a JSON map.
  Map<String, Object?> toJson() {
    return {
      'localNetwork': localNetwork.name,
      'location': location.name,
      'bluetooth': bluetooth.name,
      'notifications': notifications.name,
      if (missingManifestPermissions.isNotEmpty) 'missingManifestPermissions': missingManifestPermissions,
      if (missingInfoPlistKeys.isNotEmpty) 'missingInfoPlistKeys': missingInfoPlistKeys,
      if (platformDetails.isNotEmpty) 'platformDetails': platformDetails,
    };
  }

  static PermissionStatus _parseStatus(Object? val) {
    if (val is! String) return PermissionStatus.unknown;
    return PermissionStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => PermissionStatus.unknown,
    );
  }
}

/// The status of a permission.
enum PermissionStatus {
  unknown,
  granted,
  denied,
  restricted,
  permanentlyDenied,
  notDetermined,
}

/// The type of permission to request.
enum DiscoveryPermissionType {
  localNetwork,
  location,
  bluetooth,
  notifications,
}
