/// Resolves MAC addresses to hardware manufacturers using an offline IEEE OUI lookup database.
class OuiVendorResolver {
  const OuiVendorResolver._();

  /// Normalized OUI prefix map (top IoT, networking, computing, and smart home vendors).
  static const Map<String, String> _ouiPrefixes = <String, String>{
    // Apple
    '00:03:93': 'Apple, Inc.',
    '00:05:02': 'Apple, Inc.',
    '00:0a:27': 'Apple, Inc.',
    '00:0a:95': 'Apple, Inc.',
    '00:0d:93': 'Apple, Inc.',
    '00:10:fa': 'Apple, Inc.',
    '00:11:24': 'Apple, Inc.',
    '00:14:51': 'Apple, Inc.',
    '00:16:cb': 'Apple, Inc.',
    '00:17:f2': 'Apple, Inc.',
    '00:19:e3': 'Apple, Inc.',
    '00:1b:63': 'Apple, Inc.',
    '00:1c:b3': 'Apple, Inc.',
    '00:1d:4f': 'Apple, Inc.',
    '00:1e:52': 'Apple, Inc.',
    '00:1e:c2': 'Apple, Inc.',
    '00:1f:5b': 'Apple, Inc.',
    '00:1f:f3': 'Apple, Inc.',
    '00:21:e9': 'Apple, Inc.',
    '00:22:41': 'Apple, Inc.',
    '00:23:12': 'Apple, Inc.',
    '00:23:32': 'Apple, Inc.',
    '00:23:6c': 'Apple, Inc.',
    '00:23:df': 'Apple, Inc.',
    '00:24:36': 'Apple, Inc.',
    '00:25:00': 'Apple, Inc.',
    '00:25:4b': 'Apple, Inc.',
    '00:25:bc': 'Apple, Inc.',
    '00:26:08': 'Apple, Inc.',
    '00:26:4a': 'Apple, Inc.',
    '00:26:b0': 'Apple, Inc.',
    '00:26:bb': 'Apple, Inc.',
    '3c:06:30': 'Apple, Inc.',
    '3c:22:fb': 'Apple, Inc.',
    '40:6c:8f': 'Apple, Inc.',
    '60:f8:1d': 'Apple, Inc.',
    'a4:83:e7': 'Apple, Inc.',
    'ac:bc:32': 'Apple, Inc.',
    'f0:18:98': 'Apple, Inc.',
    'f4:5c:89': 'Apple, Inc.',

    // Espressif (ESP8266, ESP32 Smart Home Devices)
    '18:fe:34': 'Espressif Systems',
    '24:0a:c4': 'Espressif Systems',
    '24:62:ab': 'Espressif Systems',
    '24:6f:28': 'Espressif Systems',
    '24:a1:60': 'Espressif Systems',
    '24:b2:de': 'Espressif Systems',
    '2c:f4:32': 'Espressif Systems',
    '30:ae:a4': 'Espressif Systems',
    '34:94:54': 'Espressif Systems',
    '3c:61:05': 'Espressif Systems',
    '3c:71:bf': 'Espressif Systems',
    '3c:84:27': 'Espressif Systems',
    '40:22:d8': 'Espressif Systems',
    '40:91:51': 'Espressif Systems',
    '48:3fda': 'Espressif Systems',
    '48:55:19': 'Espressif Systems',
    '54:43:b2': 'Espressif Systems',
    '68:c6:3a': 'Espressif Systems',
    '80:7d:3a': 'Espressif Systems',
    '84:0d:8e': 'Espressif Systems',
    '84:cc:a8': 'Espressif Systems',
    '84:f3:eb': 'Espressif Systems',
    '90:38:0a': 'Espressif Systems',
    '94:b5:55': 'Espressif Systems',
    '94:b9:7e': 'Espressif Systems',
    'a0:20:a6': 'Espressif Systems',
    'a4:e5:7c': 'Espressif Systems',
    'ac:67:b2': 'Espressif Systems',
    'b4:e6:2d': 'Espressif Systems',
    'bc:dd:c2': 'Espressif Systems',
    'c4:4f:33': 'Espressif Systems',
    'c8:2b:96': 'Espressif Systems',
    'd8:bc:38': 'Espressif Systems',
    'dc:4f:22': 'Espressif Systems',
    'ec:94:cb': 'Espressif Systems',

    // Raspberry Pi
    'b8:27:eb': 'Raspberry Pi Foundation',
    'dc:a6:32': 'Raspberry Pi Trading Ltd',
    'e4:5f:01': 'Raspberry Pi Trading Ltd',
    '28:cd:c1': 'Raspberry Pi (Trading) Ltd',

    // Google / Nest
    '00:1a:11': 'Google LLC',
    'f4:f5:d8': 'Google LLC',
    'f4:03:04': 'Google LLC',
    'd8:6c:63': 'Google LLC',
    '54:60:09': 'Google LLC',
    '18:b4:30': 'Nest Labs Inc.',
    '64:16:66': 'Nest Labs Inc.',

    // Philips / Signify (Hue)
    '00:17:88': 'Signify / Philips Lighting BV',
    'ec:b5:fa': 'Signify / Philips Lighting BV',

    // Sonos
    '00:0e:58': 'Sonos, Inc.',
    '5c:aa:fd': 'Sonos, Inc.',
    '78:28:ca': 'Sonos, Inc.',
    '94:9f:3e': 'Sonos, Inc.',
    'b8:e9:37': 'Sonos, Inc.',

    // Samsung
    '00:07:ab': 'Samsung Electronics',
    '00:12:47': 'Samsung Electronics',
    '00:15:b9': 'Samsung Electronics',
    '00:16:32': 'Samsung Electronics',
    '00:17:c9': 'Samsung Electronics',
    '00:18:af': 'Samsung Electronics',
    '00:1a:8a': 'Samsung Electronics',
    '00:1c:43': 'Samsung Electronics',
    '00:1d:25': 'Samsung Electronics',
    '00:1e:7d': 'Samsung Electronics',
    '00:1f:cc': 'Samsung Electronics',
    '00:21:19': 'Samsung Electronics',
    '00:23:d6': 'Samsung Electronics',
    '00:24:54': 'Samsung Electronics',
    '00:26:5d': 'Samsung Electronics',

    // Sony
    '00:01:4a': 'Sony Group Corporation',
    '00:04:1f': 'Sony Group Corporation',
    '00:13:15': 'Sony Group Corporation',
    '00:15:c1': 'Sony Group Corporation',
    '00:19:c5': 'Sony Group Corporation',
    '00:1a:80': 'Sony Group Corporation',
    '00:1d:ba': 'Sony Group Corporation',
    '00:24:be': 'Sony Group Corporation',
    'f8:46:1c': 'Sony Interactive Entertainment Inc.',

    // HP (Printers & Computers)
    '00:01:e6': 'HP Inc.',
    '00:01:e7': 'HP Inc.',
    '00:02:a5': 'HP Inc.',
    '00:04:ea': 'HP Inc.',
    '00:08:02': 'HP Inc.',
    '00:08:83': 'HP Inc.',
    '00:0e:7f': 'HP Inc.',
    '00:10:83': 'HP Inc.',
    '00:11:0a': 'HP Inc.',
    '00:11:85': 'HP Inc.',
    '00:12:79': 'HP Inc.',
    '00:13:21': 'HP Inc.',
    '00:14:38': 'HP Inc.',
    '00:14:c2': 'HP Inc.',
    '00:15:60': 'HP Inc.',
    '00:16:35': 'HP Inc.',
    '00:17:08': 'HP Inc.',
    '00:17:a4': 'HP Inc.',
    '00:18:71': 'HP Inc.',
    '00:18:fe': 'HP Inc.',
    '00:19:bb': 'HP Inc.',
    '00:1a:4b': 'HP Inc.',
    '00:1b:78': 'HP Inc.',
    '00:1c:c4': 'HP Inc.',
    '00:1e:0b': 'HP Inc.',
    '00:1f:29': 'HP Inc.',
    '00:21:5a': 'HP Inc.',
    '00:22:64': 'HP Inc.',
    '00:23:7d': 'HP Inc.',
    '00:24:81': 'HP Inc.',
    '00:25:b3': 'HP Inc.',
    '00:26:55': 'HP Inc.',

    // Canon
    '00:00:85': 'Canon Inc.',
    '00:1e:8f': 'Canon Inc.',
    '70:85:c2': 'Canon Inc.',
    '84:ba:3b': 'Canon Inc.',

    // Epson
    '00:00:48': 'Seiko Epson Corp.',
    '00:21:b7': 'Seiko Epson Corp.',
    '00:26:ab': 'Seiko Epson Corp.',

    // TP-Link
    '00:31:92': 'TP-Link Corporation Limited',
    '14:cc:20': 'TP-Link Technologies Co., Ltd.',
    '50:c7:bf': 'TP-Link Technologies Co., Ltd.',
    '60:32:b1': 'TP-Link Technologies Co., Ltd.',
    'e8:48:b8': 'TP-Link Technologies Co., Ltd.',
    'f4:f2:6d': 'TP-Link Technologies Co., Ltd.',

    // Synology
    '00:11:32': 'Synology Incorporated',

    // QNAP
    '00:08:9b': 'QNAP Systems, Inc.',
    '24:5e:be': 'QNAP Systems, Inc.',

    // Hikvision (IP Cameras)
    '44:19:b6': 'Hangzhou Hikvision Digital Technology Co., Ltd.',
    'bc:5e:63': 'Hangzhou Hikvision Digital Technology Co., Ltd.',
    'c0:56:e3': 'Hangzhou Hikvision Digital Technology Co., Ltd.',

    // Dahua (IP Cameras)
    '3c:ef:8c': 'Zhejiang Dahua Technology Co., Ltd.',
    '90:02:a9': 'Zhejiang Dahua Technology Co., Ltd.',

    // Roku
    '00:0d:4b': 'Roku, Inc.',
    'b0:ee:45': 'Roku, Inc.',
    'd8:31:34': 'Roku, Inc.',

    // Amazon
    '00:fc:8b': 'Amazon Technologies Inc.',
    '44:65:0d': 'Amazon Technologies Inc.',
    '68:37:e9': 'Amazon Technologies Inc.',
    '74:75:48': 'Amazon Technologies Inc.',
    '88:71:e5': 'Amazon Technologies Inc.',
    'ac:63:be': 'Amazon Technologies Inc.',
    'f0:27:2d': 'Amazon Technologies Inc.',
    'f0:81:73': 'Amazon Technologies Inc.',
  };

  /// Looks up a hardware manufacturer by MAC address.
  ///
  /// Accepts formats like `AA:BB:CC:DD:EE:FF`, `aa-bb-cc-dd-ee-ff`, or `aabbccddeeff`.
  /// Returns `null` if the MAC is invalid or unmapped.
  static String? lookupMac(String? macAddress) {
    if (macAddress == null || macAddress.isEmpty) return null;

    // Strip delimiters and lower-case
    final clean = macAddress
        .replaceAll(':', '')
        .replaceAll('-', '')
        .replaceAll('.', '')
        .toLowerCase();

    if (clean.length < 6) return null;

    // Extract first 6 hex characters (24-bit OUI)
    final prefix =
        '${clean.substring(0, 2)}:${clean.substring(2, 4)}:${clean.substring(4, 6)}';

    return _ouiPrefixes[prefix];
  }
}
