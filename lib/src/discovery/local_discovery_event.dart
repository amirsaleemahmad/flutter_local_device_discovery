import '../models/local_device.dart';
import '../models/local_service.dart';

/// An event emitted by a discovery session.
sealed class LocalDiscoveryEvent {
  const LocalDiscoveryEvent();
}

/// Emitted when a discovery session starts.
class LocalDiscoveryStarted extends LocalDiscoveryEvent {
  const LocalDiscoveryStarted();
}

/// Emitted when a device is added.
class LocalDeviceAdded extends LocalDiscoveryEvent {
  const LocalDeviceAdded(this.device);

  /// The added device.
  final LocalDevice device;
}

/// Emitted when a device is updated.
class LocalDeviceUpdated extends LocalDiscoveryEvent {
  const LocalDeviceUpdated(this.device);

  /// The updated device.
  final LocalDevice device;
}

/// Emitted when a device is removed.
class LocalDeviceRemoved extends LocalDiscoveryEvent {
  const LocalDeviceRemoved(this.device);

  /// The removed device.
  final LocalDevice device;
}

/// Emitted when a service is added.
class LocalServiceAdded extends LocalDiscoveryEvent {
  const LocalServiceAdded(this.service);

  /// The added service.
  final LocalService service;
}

/// Emitted when a service is updated.
class LocalServiceUpdated extends LocalDiscoveryEvent {
  const LocalServiceUpdated(this.service);

  /// The updated service.
  final LocalService service;
}

/// Emitted when a service is removed.
class LocalServiceRemoved extends LocalDiscoveryEvent {
  const LocalServiceRemoved(this.service);

  /// The removed service.
  final LocalService service;
}

/// Emitted when the network configuration changes.
class LocalNetworkChanged extends LocalDiscoveryEvent {
  const LocalNetworkChanged();
}

/// Emitted when a non-fatal warning occurs.
class LocalDiscoveryWarning extends LocalDiscoveryEvent {
  const LocalDiscoveryWarning(this.message);

  /// The warning message.
  final String message;
}

/// Emitted when a discovery failure occurs.
class LocalDiscoveryFailure extends LocalDiscoveryEvent {
  const LocalDiscoveryFailure(this.error);

  /// The error that occurred.
  final Object error;
}

/// Emitted when a discovery session stops.
class LocalDiscoveryStopped extends LocalDiscoveryEvent {
  const LocalDiscoveryStopped();
}
