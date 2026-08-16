import 'dart:async';
import 'dart:io';

/// Diagnostics for verifying if the local network allows UDP multicast communication.
class MulticastHealthChecker {
  const MulticastHealthChecker._();

  /// Multicast test group address.
  static final InternetAddress _testMulticastGroup =
      InternetAddress('239.255.255.250');

  /// Runs a lightweight multicast loopback probe to check if UDP multicast
  /// packets are successfully delivered on the local network interface.
  ///
  /// Returns `true` if multicast traffic is healthy, or `false` if blocked/dropped.
  static Future<bool> checkMulticastHealth({
    Duration timeout = const Duration(milliseconds: 1500),
  }) async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
        reusePort: true,
      );

      socket.multicastLoopback = true;
      socket.multicastHops = 1;

      try {
        socket.joinMulticast(_testMulticastGroup);
      } catch (_) {
        // Platform or interface might restrict group join
      }

      final completer = Completer<bool>();
      final payload =
          'FLDD_MULTICAST_PROBE_${DateTime.now().millisecondsSinceEpoch}';
      final bytes = payload.codeUnits;

      final subscription = socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket?.receive();
          if (datagram != null) {
            final received = String.fromCharCodes(datagram.data);
            if (received == payload && !completer.isCompleted) {
              completer.complete(true);
            }
          }
        }
      });

      // Send the test packet
      socket.send(bytes, _testMulticastGroup, 1900);

      final result = await completer.future
          .timeout(timeout, onTimeout: () => false)
          .whenComplete(() {
        subscription.cancel();
      });

      return result;
    } catch (_) {
      return false;
    } finally {
      socket?.close();
    }
  }
}
