import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'models/native_discovery_capabilities.dart';
import 'models/native_discovery_diagnostics.dart';
import 'models/native_discovery_event.dart';
import 'models/native_discovery_readiness.dart';
import 'models/native_discovery_request.dart';
import 'models/native_service_registration.dart';
import 'models/native_service_registration_result.dart';
import 'method_channel_impl.dart';

/// The platform interface for [FlutterLocalDeviceDiscoveryPlatform].
abstract class FlutterLocalDeviceDiscoveryPlatform extends PlatformInterface {
  /// Constructs a [FlutterLocalDeviceDiscoveryPlatform].
  FlutterLocalDeviceDiscoveryPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterLocalDeviceDiscoveryPlatform _instance =
      MethodChannelFlutterLocalDeviceDiscovery();

  /// The default instance of [FlutterLocalDeviceDiscoveryPlatform].
  static FlutterLocalDeviceDiscoveryPlatform get instance => _instance;

  /// Platform-specific plugins should override this with their own platform-specific
  /// class that extends [FlutterLocalDeviceDiscoveryPlatform].
  static set instance(FlutterLocalDeviceDiscoveryPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the capabilities supported by this platform.
  Future<NativeDiscoveryCapabilities> getCapabilities() {
    throw UnimplementedError('getCapabilities() has not been implemented.');
  }

  /// Checks readiness for a discovery request.
  Future<NativeDiscoveryReadiness> checkReadiness(
    NativeDiscoveryRequest request,
  ) {
    throw UnimplementedError('checkReadiness() has not been implemented.');
  }

  /// Starts a discovery session and returns its session ID.
  Future<String> startDiscovery(NativeDiscoveryRequest request) {
    throw UnimplementedError('startDiscovery() has not been implemented.');
  }

  /// Returns the event stream for a discovery session.
  Stream<NativeDiscoveryEvent> eventsForSession(String sessionId) {
    throw UnimplementedError('eventsForSession() has not been implemented.');
  }

  /// Pauses a discovery session.
  Future<void> pauseDiscovery(String sessionId) {
    throw UnimplementedError('pauseDiscovery() has not been implemented.');
  }

  /// Resumes a discovery session.
  Future<void> resumeDiscovery(String sessionId) {
    throw UnimplementedError('resumeDiscovery() has not been implemented.');
  }

  /// Stops a discovery session.
  Future<void> stopDiscovery(String sessionId) {
    throw UnimplementedError('stopDiscovery() has not been implemented.');
  }

  /// Registers a local service.
  Future<NativeServiceRegistrationResult> registerService(
    NativeServiceRegistration request,
  ) {
    throw UnimplementedError('registerService() has not been implemented.');
  }

  /// Updates TXT records for a registered service.
  Future<void> updateRegisteredService(
    String registrationId,
    Map<String, dynamic> txtRecords,
  ) {
    throw UnimplementedError(
      'updateRegisteredService() has not been implemented.',
    );
  }

  /// Unregisters a local service.
  Future<void> unregisterService(String registrationId) {
    throw UnimplementedError('unregisterService() has not been implemented.');
  }

  /// Returns native discovery diagnostics.
  Future<NativeDiscoveryDiagnostics> getDiagnostics() {
    throw UnimplementedError('getDiagnostics() has not been implemented.');
  }

  /// Starts the native SSDP discovery engine.
  /// Returns a session ID for the SSDP engine.
  Future<String> startNativeSsdp({
    required List<String> searchTargets,
    required int searchIntervalMs,
    required bool includeLoopback,
    required bool includeLinkLocal,
    required bool includeVpnInterfaces,
  }) {
    throw UnimplementedError('startNativeSsdp() has not been implemented.');
  }

  /// Stops the native SSDP discovery engine.
  Future<void> stopNativeSsdp(String sessionId) {
    throw UnimplementedError('stopNativeSsdp() has not been implemented.');
  }

  /// Returns a stream of native SSDP events.
  Stream<NativeDiscoveryEvent> nativeSsdpEvents(String sessionId) {
    throw UnimplementedError('nativeSsdpEvents() has not been implemented.');
  }

  /// Starts the native WS-Discovery engine.
  Future<String> startNativeWsDiscovery({
    required List<String> wsDiscoveryTypes,
    required int searchIntervalMs,
    required bool includeLoopback,
    required bool includeLinkLocal,
    required bool includeVpnInterfaces,
  }) {
    throw UnimplementedError('startNativeWsDiscovery() has not been implemented.');
  }

  /// Stops the native WS-Discovery engine.
  Future<void> stopNativeWsDiscovery(String sessionId) {
    throw UnimplementedError('stopNativeWsDiscovery() has not been implemented.');
  }

  /// Returns a stream of native WS-Discovery events.
  Stream<NativeDiscoveryEvent> nativeWsDiscoveryEvents(String sessionId) {
    throw UnimplementedError('nativeWsDiscoveryEvents() has not been implemented.');
  }

  /// Returns network info (SSID, BSSID, signal, gateway, etc.).
  Future<Map<String, Object?>> getNetworkInfo() {
    throw UnimplementedError('getNetworkInfo() has not been implemented.');
  }

  /// Pings a host using native ICMP.
  Future<Map<String, Object?>> icmpPing(String address, int timeoutMs) {
    throw UnimplementedError('icmpPing() has not been implemented.');
  }

  /// Returns gateway info for network topology.
  Future<Map<String, Object?>> getGatewayInfo() {
    throw UnimplementedError('getGatewayInfo() has not been implemented.');
  }

  /// Checks discovery-related permissions.
  Future<Map<String, Object?>> checkPermissions() {
    throw UnimplementedError('checkPermissions() has not been implemented.');
  }

  /// Requests discovery-related permissions.
  Future<Map<String, Object?>> requestPermissions(List<int> permissionTypes) {
    throw UnimplementedError('requestPermissions() has not been implemented.');
  }
}
