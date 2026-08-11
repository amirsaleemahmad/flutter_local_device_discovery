import 'dart:async';
import 'dart:io';

import '../models/local_device.dart';

/// Utility to safely check the reachability of a network host.
class ReachabilityProber {
  /// Safely probes a host at [address] by attempting to connect to common ports.
  static Future<LocalDeviceReachability> probe(
    String address, {
    List<int> ports = const [80, 443, 8080, 554, 8000],
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final stopwatch = Stopwatch()..start();

    for (final port in ports) {
      try {
        final socket = await Socket.connect(
          address,
          port,
          timeout: timeout,
        );
        await socket.close();
        stopwatch.stop();
        return LocalDeviceReachability(
          status: LocalReachabilityStatus.reachable,
          lastCheckedAt: DateTime.now(),
          latency: stopwatch.elapsed,
          successfulAddress: address,
          successfulPort: port,
          methods: const {LocalReachabilityMethod.tcpConnect},
        );
      } on Object catch (_) {
        // Continue to the next port
      }
    }

    stopwatch.stop();
    return LocalDeviceReachability(
      status: LocalReachabilityStatus.unreachable,
      lastCheckedAt: DateTime.now(),
      methods: const {LocalReachabilityMethod.tcpConnect},
    );
  }
}
