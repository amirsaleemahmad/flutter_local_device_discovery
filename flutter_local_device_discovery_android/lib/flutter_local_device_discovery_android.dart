import 'package:flutter_local_device_discovery_platform_interface/flutter_local_device_discovery_platform_interface.dart';

/// The Android implementation of [FlutterLocalDeviceDiscoveryPlatform].
class FlutterLocalDeviceDiscoveryAndroid
    extends MethodChannelFlutterLocalDeviceDiscovery {
  /// Registers this class as the default instance on Android.
  static void registerWith() {
    FlutterLocalDeviceDiscoveryPlatform.instance =
        FlutterLocalDeviceDiscoveryAndroid();
  }
}