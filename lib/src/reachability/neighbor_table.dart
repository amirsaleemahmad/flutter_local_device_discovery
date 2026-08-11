import 'dart:io';

/// Represents an entry in the local ARP/neighbor table.
class NeighborTableEntry {
  const NeighborTableEntry({
    required this.ipAddress,
    required this.macAddress,
    required this.interfaceName,
    required this.state,
  });

  final String ipAddress;
  final String macAddress;
  final String interfaceName;
  final String state;

  Map<String, String> toMap() {
    return {
      'ipAddress': ipAddress,
      'macAddress': macAddress,
      'interfaceName': interfaceName,
      'state': state,
    };
  }
}

/// Utility to read and inspect the local ARP/neighbor table where permitted.
class NeighborTable {
  /// Reads entries from the system ARP table (e.g. /proc/net/arp on Android/Linux).
  static Future<List<NeighborTableEntry>> getEntries() async {
    try {
      if (Platform.isAndroid || Platform.isLinux) {
        final file = File('/proc/net/arp');
        if (await file.exists()) {
          final lines = await file.readAsLines();
          final entries = <NeighborTableEntry>[];
          // Skip header line
          for (var i = 1; i < lines.length; i++) {
            final line = lines[i].trim();
            if (line.isEmpty) continue;
            final parts = line.split(RegExp(r'\s+'));
            if (parts.length >= 6) {
              entries.add(
                NeighborTableEntry(
                  ipAddress: parts[0],
                  macAddress: parts[3],
                  interfaceName: parts[5],
                  state: parts[2], // Flags
                ),
              );
            }
          }
          return entries;
        }
      }
    } on Object catch (_) {
      // Ignore and return empty list on permission/IO failure
    }
    return const <NeighborTableEntry>[];
  }
}
