import 'dart:io';

class LinuxNetworkInfo {
  static Future<String?> getDefaultGateway() async {
    try {
      final file = File('/proc/net/route');
      if (!await file.exists()) return null;
      
      final lines = await file.readAsLines();
      for (var i = 1; i < lines.length; i++) {
        final parts = lines[i].split(RegExp(r'\s+'));
        if (parts.length >= 8 && parts[1] == '00000000') {
          final gatewayHex = parts[2];
          if (gatewayHex.length == 8) {
            final a = int.parse(gatewayHex.substring(6, 8), radix: 16);
            final b = int.parse(gatewayHex.substring(4, 6), radix: 16);
            final c = int.parse(gatewayHex.substring(2, 4), radix: 16);
            final d = int.parse(gatewayHex.substring(0, 2), radix: 16);
            return '$a.$b.$c.$d';
          }
        }
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }
}
