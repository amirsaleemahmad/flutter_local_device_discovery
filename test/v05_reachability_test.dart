import 'dart:io';
import 'package:flutter_local_device_discovery/flutter_local_device_discovery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Reachability Prober and Neighbor Table', () {
    test('ReachabilityProber returns unreachable status on failed connections', () async {
      // Connect to an invalid address/port that will timeout/fail
      final result = await ReachabilityProber.probe(
        '254.254.254.254',
        ports: [9999],
        timeout: const Duration(milliseconds: 50),
      );

      expect(result.status, LocalReachabilityStatus.unreachable);
      expect(result.successfulAddress, isNull);
      expect(result.successfulPort, isNull);
      expect(result.methods, contains(LocalReachabilityMethod.tcpConnect));
    });

    test('ReachabilityProber reports reachable when local TCP server accepts connection', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;

      final resultFuture = ReachabilityProber.probe(
        InternetAddress.loopbackIPv4.address,
        ports: [port],
        timeout: const Duration(seconds: 1),
      );

      final socket = await server.first;
      await socket.close();
      await server.close();

      final result = await resultFuture;
      expect(result.status, LocalReachabilityStatus.reachable);
      expect(result.successfulAddress, InternetAddress.loopbackIPv4.address);
      expect(result.successfulPort, port);
    });

    test('NeighborTable returns empty list or valid entries without throwing', () async {
      final entries = await NeighborTable.getEntries();
      expect(entries, isNotNull);
      if (entries.isNotEmpty) {
        final entry = entries.first;
        expect(entry.ipAddress, isNotEmpty);
        expect(entry.macAddress, isNotEmpty);
        expect(entry.interfaceName, isNotEmpty);
        expect(entry.toMap(), isNotEmpty);
      }
    });
  });
}
