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
      : _channel = channel ??
            const MethodChannel(
              'flutter_local_device_discovery',
            );

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
    return _globalEventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => NativeDiscoveryEvent.fromMap(
              event as Map<Object?, Object?>,
            ));
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
}