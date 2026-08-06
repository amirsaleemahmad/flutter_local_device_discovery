import 'package:flutter_local_device_discovery_platform_interface/flutter_local_device_discovery_platform_interface.dart';

/// The Apple platform implementation of [FlutterLocalDeviceDiscoveryPlatform].
class FlutterLocalDeviceDiscoveryDarwin
    extends MethodChannelFlutterLocalDeviceDiscovery {
  /// Registers this class as the default instance on iOS and macOS.
  static void registerWith() {
    FlutterLocalDeviceDiscoveryPlatform.instance =
        FlutterLocalDeviceDiscoveryDarwin();
  }
}