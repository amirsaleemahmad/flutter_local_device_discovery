import '../models/ssdp_device.dart';

/// The kind of SSDP datagram received by the discovery engine.
enum SsdpMessageKind { searchResponse, alive, update, byebye, unknown }

/// A parsed SSDP response or notification.
class SsdpMessage {
  const SsdpMessage({
    required this.startLine,
    required this.headers,
    required this.kind,
  });

  /// The HTTP-like first line of the datagram.
  final String startLine;

  /// Lower-case header names mapped to trimmed values.
  final Map<String, String> headers;

  /// The semantic SSDP message kind.
  final SsdpMessageKind kind;

  String? get usn => headers['usn'];
  String? get location => headers['location'];
  String? get searchTarget => headers['st'] ?? headers['nt'];
  String? get server => headers['server'];
  String? get bootId => headers['bootid.upnp.org'];
  String? get configId => headers['configid.upnp.org'];

  /// A stable root identifier for advertisements from the same UPnP device.
  String? get deviceKey {
    final value = usn?.trim();
    if (value == null || value.isEmpty) return null;
    return value.split('::').first.toLowerCase();
  }

  /// The `CACHE-CONTROL: max-age` value, when present.
  int? get cacheControlMaxAge {
    final value = headers['cache-control'];
    if (value == null) return null;
    final match = RegExp(
      r'(?:^|[,;\s])max-age\s*=\s*"?(\d+)',
      caseSensitive: false,
    ).firstMatch(value);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  /// Converts a live response into the public SSDP device model.
  SsdpDevice? toDevice({String? sourceAddress, DateTime? observedAt}) {
    final messageUsn = usn?.trim();
    final messageLocation = location?.trim();
    final target = searchTarget?.trim();
    if (messageUsn == null ||
        messageUsn.isEmpty ||
        messageLocation == null ||
        messageLocation.isEmpty ||
        target == null ||
        target.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(messageLocation);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;

    return SsdpDevice(
      location: uri.toString(),
      usn: messageUsn,
      searchTarget: target,
      server: server,
      cacheControlMaxAge: cacheControlMaxAge,
      bootId: bootId,
      configId: configId,
      sourceAddress: sourceAddress,
      headers: headers,
      lastSeenAt: observedAt ?? DateTime.now(),
    );
  }
}

/// Parses the HTTP-like wire format used by SSDP.
abstract final class SsdpMessageParser {
  /// Parses [data], returning `null` for malformed or unrelated datagrams.
  static SsdpMessage? tryParse(String data) {
    if (data.isEmpty || data.length > 64 * 1024) return null;

    final lines = data.split(RegExp(r'\r?\n'));
    if (lines.isEmpty) return null;
    final startLine = lines.first.trim();
    if (startLine.isEmpty) return null;

    final upper = startLine.toUpperCase();
    final isResponse = upper.startsWith('HTTP/1.1 200');
    final isNotify = upper.startsWith('NOTIFY ');
    if (!isResponse && !isNotify) return null;

    final headers = <String, String>{};
    for (final rawLine in lines.skip(1)) {
      final line = rawLine.trim();
      if (line.isEmpty) break;
      final separator = line.indexOf(':');
      if (separator <= 0) continue;
      final name = line.substring(0, separator).trim().toLowerCase();
      final value = line.substring(separator + 1).trim();
      if (name.isEmpty || value.isEmpty) continue;
      headers.putIfAbsent(name, () => value);
    }

    final kind = isResponse
        ? SsdpMessageKind.searchResponse
        : switch (headers['nts']?.toLowerCase()) {
            'ssdp:alive' => SsdpMessageKind.alive,
            'ssdp:update' => SsdpMessageKind.update,
            'ssdp:byebye' => SsdpMessageKind.byebye,
            _ => SsdpMessageKind.unknown,
          };

    if (headers['usn'] == null) return null;
    return SsdpMessage(
      startLine: startLine,
      headers: Map<String, String>.unmodifiable(headers),
      kind: kind,
    );
  }
}
