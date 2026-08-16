import 'dart:async';

import '../discovery/local_discovery_event.dart';
import '../discovery/local_discovery_request.dart';

/// Interface for custom discovery protocol adapters.
///
/// Implement this class to add support for specialized, proprietary, or IoT protocols
/// (e.g. CoAP, BLE Wi-Fi provisioning bridges, custom UDP beacons) into the unified
/// discovery session and aggregator pipeline.
abstract class DiscoveryProtocolAdapter {
  /// Unique identifier of this protocol adapter (e.g., 'coap', 'ble_bridge').
  String get protocolId;

  /// Starts discovery using this adapter with the given [request].
  ///
  /// Emits normalized [LocalDiscoveryEvent] instances that will be aggregated into
  /// the main session's device list.
  Stream<LocalDiscoveryEvent> start(LocalDiscoveryRequest request);

  /// Stops discovery and releases any underlying sockets, threads, or resources.
  Future<void> stop();
}
