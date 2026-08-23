import 'dart:async';

import 'package:flutter/services.dart';

import 'models/native_discovery_capabilities.dart';
import 'models/native_discovery_diagnostics.dart';
import 'models/native_discovery_event.dart';
import 'models/native_discovery_readiness.dart';
import 'models/native_discovery_request.dart';
import 'models/native_service_registration.dart';
import 'models/native_service_registration_result.dart';
import 'platform_interface.dart';

/// The default method-channel implementation of
/// [FlutterLocalDeviceDiscoveryPlatform].
class MethodChannelFlutterLocalDeviceDiscovery
    extends FlutterLocalDeviceDiscoveryPlatform {
  /// Creates a new [MethodChannelFlutterLocalDeviceDiscovery].
  MethodChannelFlutterLocalDeviceDiscovery({MethodChannel? channel})
      : _channel =
            channel ?? const MethodChannel('flutter_local_device_discovery');

  final MethodChannel _channel;

  static const EventChannel _eventChannel = EventChannel(
    'flutter_local_device_discovery/events',
  );

  Stream<NativeDiscoveryEvent>? _globalEventStream;

  @override
  Future<NativeDiscoveryCapabilities> getCapabilities() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'getCapabilities',
    );
    if (result == null) {
      throw PlatformException(
        code: 'null_result',
        message: 'getCapabilities returned null',
      );
    }
    return NativeDiscoveryCapabilities.fromMap(result);
  }

  @override
  Future<NativeDiscoveryReadiness> checkReadiness(
    NativeDiscoveryRequest request,
  ) async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'checkReadiness',
      request.toMap(),
    );
    if (result == null) {
      throw PlatformException(
        code: 'null_result',
        message: 'checkReadiness returned null',
      );
    }
    return NativeDiscoveryReadiness.fromMap(result);
  }

  @override
  Future<String> startDiscovery(NativeDiscoveryRequest request) async {
    final result = await _channel.invokeMethod<String>(
      'startDiscovery',
      request.toMap(),
    );
    if (result == null) {
      throw PlatformException(
        code: 'null_result',
        message: 'startDiscovery returned null',
      );
    }
    return result;
  }

  @override
  Stream<NativeDiscoveryEvent> eventsForSession(String sessionId) {
    final global = _globalEventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map(
          (event) =>
              NativeDiscoveryEvent.fromMap(event as Map<Object?, Object?>),
        )
        .asBroadcastStream();
    return global.where(
      (event) => event.sessionId == null || event.sessionId == sessionId,
    );
  }

  @override
  Future<void> pauseDiscovery(String sessionId) async {
    await _channel.invokeMethod<void>('pauseDiscovery', sessionId);
  }

  @override
  Future<void> resumeDiscovery(String sessionId) async {
    await _channel.invokeMethod<void>('resumeDiscovery', sessionId);
  }

  @override
  Future<void> stopDiscovery(String sessionId) async {
    await _channel.invokeMethod<void>('stopDiscovery', sessionId);
  }

  @override
  Future<NativeServiceRegistrationResult> registerService(
    NativeServiceRegistration request,
  ) async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'registerService',
      request.toMap(),
    );
    if (result == null) {
      throw PlatformException(
        code: 'null_result',
        message: 'registerService returned null',
      );
    }
    return NativeServiceRegistrationResult.fromMap(result);
  }

  @override
  Future<void> updateRegisteredService(
    String registrationId,
    Map<String, dynamic> txtRecords,
  ) async {
    await _channel.invokeMethod<void>(
      'updateRegisteredService',
      <String, Object?>{
        'registrationId': registrationId,
        'txtRecords': txtRecords,
      },
    );
  }

  @override
  Future<void> unregisterService(String registrationId) async {
    await _channel.invokeMethod<void>('unregisterService', registrationId);
  }

  @override
  Future<NativeDiscoveryDiagnostics> getDiagnostics() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'getDiagnostics',
    );
    if (result == null) {
      throw PlatformException(
        code: 'null_result',
        message: 'getDiagnostics returned null',
      );
    }
    return NativeDiscoveryDiagnostics.fromMap(result);
  }

  static const EventChannel _nativeSsdpEventChannel = EventChannel(
    'flutter_local_device_discovery/native_ssdp_events',
  );
  Stream<NativeDiscoveryEvent>? _globalNativeSsdpEventStream;

  static const EventChannel _nativeWsDiscoveryEventChannel = EventChannel(
    'flutter_local_device_discovery/native_ws_discovery_events',
  );
  Stream<NativeDiscoveryEvent>? _globalNativeWsDiscoveryEventStream;

  @override
  Future<String> startNativeSsdp({
    required List<String> searchTargets,
    required int searchIntervalMs,
    required bool includeLoopback,
    required bool includeLinkLocal,
    required bool includeVpnInterfaces,
  }) async {
    final result = await _channel.invokeMethod<String>(
      'startNativeSsdp',
      <String, Object?>{
        'searchTargets': searchTargets,
        'searchIntervalMs': searchIntervalMs,
        'includeLoopback': includeLoopback,
        'includeLinkLocal': includeLinkLocal,
        'includeVpnInterfaces': includeVpnInterfaces,
      },
    );
    if (result == null) {
      throw PlatformException(
        code: 'null_result',
        message: 'startNativeSsdp returned null',
      );
    }
    return result;
  }

  @override
  Future<void> stopNativeSsdp(String sessionId) async {
    await _channel.invokeMethod<void>('stopNativeSsdp', sessionId);
  }

  @override
  Stream<NativeDiscoveryEvent> nativeSsdpEvents(String sessionId) {
    final global = _globalNativeSsdpEventStream ??= _nativeSsdpEventChannel
        .receiveBroadcastStream()
        .map(
          (event) =>
              NativeDiscoveryEvent.fromMap(event as Map<Object?, Object?>),
        )
        .asBroadcastStream();
    return global.where(
      (event) => event.sessionId == null || event.sessionId == sessionId,
    );
  }

  @override
  Future<String> startNativeWsDiscovery({
    required List<String> wsDiscoveryTypes,
    required int searchIntervalMs,
    required bool includeLoopback,
    required bool includeLinkLocal,
    required bool includeVpnInterfaces,
  }) async {
    final result = await _channel.invokeMethod<String>(
      'startNativeWsDiscovery',
      <String, Object?>{
        'wsDiscoveryTypes': wsDiscoveryTypes,
        'searchIntervalMs': searchIntervalMs,
        'includeLoopback': includeLoopback,
        'includeLinkLocal': includeLinkLocal,
        'includeVpnInterfaces': includeVpnInterfaces,
      },
    );
    if (result == null) {
      throw PlatformException(
        code: 'null_result',
        message: 'startNativeWsDiscovery returned null',
      );
    }
    return result;
  }

  @override
  Future<void> stopNativeWsDiscovery(String sessionId) async {
    await _channel.invokeMethod<void>('stopNativeWsDiscovery', sessionId);
  }

  @override
  Stream<NativeDiscoveryEvent> nativeWsDiscoveryEvents(String sessionId) {
    final global = _globalNativeWsDiscoveryEventStream ??=
        _nativeWsDiscoveryEventChannel
            .receiveBroadcastStream()
            .map(
              (event) =>
                  NativeDiscoveryEvent.fromMap(event as Map<Object?, Object?>),
            )
            .asBroadcastStream();
    return global.where(
      (event) => event.sessionId == null || event.sessionId == sessionId,
    );
  }

  @override
  Future<Map<String, Object?>> getNetworkInfo() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'getNetworkInfo',
    );
    if (result == null) {
      throw PlatformException(
        code: 'null_result',
        message: 'getNetworkInfo returned null',
      );
    }
    return result.map((key, value) => MapEntry(key.toString(), value));
  }

  @override
  Future<Map<String, Object?>> icmpPing(String address, int timeoutMs) async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'icmpPing',
      <String, Object?>{
        'address': address,
        'timeoutMs': timeoutMs,
      },
    );
    if (result == null) {
      throw PlatformException(
        code: 'null_result',
        message: 'icmpPing returned null',
      );
    }
    return result.map((key, value) => MapEntry(key.toString(), value));
  }

  @override
  Future<Map<String, Object?>> getGatewayInfo() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'getGatewayInfo',
    );
    if (result == null) {
      throw PlatformException(
        code: 'null_result',
        message: 'getGatewayInfo returned null',
      );
    }
    return result.map((key, value) => MapEntry(key.toString(), value));
  }

  @override
  Future<Map<String, Object?>> checkPermissions() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'checkPermissions',
    );
    if (result == null) {
      return const <String, Object?>{};
    }
    return result.map((key, value) => MapEntry(key.toString(), value));
  }

  @override
  Future<Map<String, Object?>> requestPermissions(
    List<int> permissionTypes,
  ) async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'requestPermissions',
      <String, Object?>{
        'permissionTypes': permissionTypes,
      },
    );
    if (result == null) {
      return const <String, Object?>{};
    }
    return result.map((key, value) => MapEntry(key.toString(), value));
  }
}
