/// Resolves MAC addresses to hardware manufacturers using an offline IEEE OUI lookup database.
/// Detailed vendor information resolved from a MAC address OUI prefix.
class OuiVendorInfo {
  const OuiVendorInfo({
    required this.name,
    this.fullOrganizationName,
    this.country,
    this.deviceCategory,
  });

  /// Short vendor name (e.g., 'Apple, Inc.').
  final String name;

  /// Full registered organization name.
  final String? fullOrganizationName;

  /// Country of the registered organization.
  final String? country;

  /// Hint about the typical device category (e.g., 'Smart Home', 'Networking', 'Computing').
  final String? deviceCategory;
}

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

    // ASUS
    '00:1a:92': 'ASUS',
    '1c:87:2c': 'ASUS',
    '2c:fd:a1': 'ASUS',
    '38:d5:47': 'ASUS',
    '40:b0:76': 'ASUS',
    '74:d0:2b': 'ASUS',
    'ac:9e:17': 'ASUS',
    'b0:6e:bf': 'ASUS',
    'f8:32:e4': 'ASUS',

    // Netgear
    '00:09:5b': 'Netgear',
    '00:0f:b5': 'Netgear',
    '00:14:6c': 'Netgear',
    '00:1b:2f': 'Netgear',
    '00:1e:2a': 'Netgear',
    '00:1f:33': 'Netgear',
    '20:0c:c8': 'Netgear',
    '20:e5:2a': 'Netgear',
    '28:80:88': 'Netgear',
    '44:94:fc': 'Netgear',
    '6c:b0:ce': 'Netgear',
    '84:1b:5e': 'Netgear',
    'a0:21:b7': 'Netgear',
    'c4:3d:c7': 'Netgear',
    'e4:f4:c6': 'Netgear',

    // Ubiquiti
    '00:27:22': 'Ubiquiti',
    '04:18:d6': 'Ubiquiti',
    '18:e8:29': 'Ubiquiti',
    '24:5a:4c': 'Ubiquiti',
    '68:d7:9a': 'Ubiquiti',
    '74:ac:b9': 'Ubiquiti',
    '78:8a:20': 'Ubiquiti',
    '80:2a:a8': 'Ubiquiti',
    'b4:fb:e4': 'Ubiquiti',
    'dc:9f:db': 'Ubiquiti',
    'f0:9f:c2': 'Ubiquiti',
    'fc:ec:da': 'Ubiquiti',

    // Linksys/Belkin
    '00:04:5a': 'Linksys/Belkin',
    '00:06:25': 'Linksys/Belkin',
    '00:0c:41': 'Linksys/Belkin',
    '00:12:17': 'Linksys/Belkin',
    '00:14:bf': 'Linksys/Belkin',
    '00:1a:70': 'Linksys/Belkin',
    '00:1e:e5': 'Linksys/Belkin',
    '00:22:6b': 'Linksys/Belkin',
    '00:25:9c': 'Linksys/Belkin',
    '20:aa:4b': 'Linksys/Belkin',
    '58:ef:68': 'Linksys/Belkin',
    'c0:56:27': 'Linksys/Belkin',
    'e8:f7:24': 'Linksys/Belkin',

    // Mikrotik
    '00:0c:42': 'Mikrotik',
    '48:8f:5a': 'Mikrotik',
    '6c:3b:6b': 'Mikrotik',
    'b8:69:f4': 'Mikrotik',
    'cc:2d:e0': 'Mikrotik',
    'e4:8d:8c': 'Mikrotik',

    // Cisco
    '00:00:0c': 'Cisco',
    '00:01:42': 'Cisco',
    '00:01:63': 'Cisco',
    '00:01:64': 'Cisco',
    '00:01:96': 'Cisco',
    '00:01:97': 'Cisco',
    '00:01:c7': 'Cisco',
    '00:01:c9': 'Cisco',
    '00:02:3d': 'Cisco',
    '00:02:4a': 'Cisco',
    '00:02:4b': 'Cisco',
    '00:02:b9': 'Cisco',
    '00:02:ba': 'Cisco',
    '00:02:fc': 'Cisco',
    '00:02:fd': 'Cisco',

    // Dell
    '00:06:5b': 'Dell',
    '00:08:74': 'Dell',
    '00:0b:db': 'Dell',
    '00:0d:56': 'Dell',
    '00:0f:1f': 'Dell',
    '00:11:43': 'Dell',
    '00:12:3f': 'Dell',
    '00:13:72': 'Dell',
    '00:14:22': 'Dell',
    '00:15:c5': 'Dell',
    '00:18:8b': 'Dell',
    '00:19:b9': 'Dell',
    '00:1a:a0': 'Dell',
    '00:1c:23': 'Dell',
    '00:1d:09': 'Dell',
    '00:1e:4f': 'Dell',
    '00:1e:c9': 'Dell',
    '00:21:70': 'Dell',
    '00:21:9b': 'Dell',
    '00:22:19': 'Dell',
    '00:23:ae': 'Dell',
    '00:24:e8': 'Dell',
    '00:25:64': 'Dell',
    '00:26:b9': 'Dell',

    // Lenovo
    '00:06:1b': 'Lenovo',
    '00:09:2d': 'Lenovo',
    '00:12:fe': 'Lenovo',
    '00:16:d3': 'Lenovo',
    '00:1a:6b': 'Lenovo',
    '28:d2:44': 'Lenovo',
    '50:7b:9d': 'Lenovo',
    '54:ee:75': 'Lenovo',
    '70:5a:0f': 'Lenovo',
    '74:e5:0b': 'Lenovo',
    '98:fa:9b': 'Lenovo',
    'c8:5b:76': 'Lenovo',
    'e8:6a:64': 'Lenovo',

    // Intel
    '00:02:b3': 'Intel',
    '00:03:47': 'Intel',
    '00:04:23': 'Intel',
    '00:07:e9': 'Intel',
    '00:0c:f1': 'Intel',
    '00:0e:0c': 'Intel',
    '00:0e:35': 'Intel',
    '00:11:11': 'Intel',
    '00:12:f0': 'Intel',
    '00:13:02': 'Intel',
    '00:13:20': 'Intel',
    '00:13:ce': 'Intel',
    '00:13:e8': 'Intel',
    '00:15:00': 'Intel',
    '00:15:17': 'Intel',
    '00:16:6f': 'Intel',
    '00:16:76': 'Intel',
    '00:16:ea': 'Intel',
    '00:16:eb': 'Intel',
    '00:17:35': 'Intel',
    '00:18:de': 'Intel',
    '00:19:d1': 'Intel',
    '00:19:d2': 'Intel',
    '00:1b:21': 'Intel',
    '00:1b:77': 'Intel',
    '00:1c:bf': 'Intel',
    '00:1d:e0': 'Intel',
    '00:1e:64': 'Intel',
    '00:1e:65': 'Intel',
    '00:1f:3b': 'Intel',
    '00:1f:3c': 'Intel',

    // Microsoft/Xbox
    '00:03:ff': 'Microsoft/Xbox',
    '00:0d:3a': 'Microsoft/Xbox',
    '00:12:5a': 'Microsoft/Xbox',
    '00:15:5d': 'Microsoft/Xbox',
    '00:17:fa': 'Microsoft/Xbox',
    '00:1d:d8': 'Microsoft/Xbox',
    '00:22:48': 'Microsoft/Xbox',
    '00:25:ae': 'Microsoft/Xbox',
    '28:18:78': 'Microsoft/Xbox',
    '48:50:73': 'Microsoft/Xbox',
    '60:45:bd': 'Microsoft/Xbox',
    '7c:1e:52': 'Microsoft/Xbox',
    'b4:0e:de': 'Microsoft/Xbox',
    'c8:3f:26': 'Microsoft/Xbox',
    'dc:53:60': 'Microsoft/Xbox',

    // Xiaomi
    '00:9e:c8': 'Xiaomi',
    '04:cf:8c': 'Xiaomi',
    '0c:1d:af': 'Xiaomi',
    '10:2a:b3': 'Xiaomi',
    '14:f6:5a': 'Xiaomi',
    '18:59:36': 'Xiaomi',
    '20:47:da': 'Xiaomi',
    '28:6c:07': 'Xiaomi',
    '34:80:b3': 'Xiaomi',
    '38:a4:ed': 'Xiaomi',
    '50:ec:50': 'Xiaomi',
    '58:44:98': 'Xiaomi',
    '64:09:80': 'Xiaomi',
    '64:cc:2e': 'Xiaomi',
    '7c:49:eb': 'Xiaomi',
    '78:02:f8': 'Xiaomi',
    '78:11:dc': 'Xiaomi',
    '9c:99:a0': 'Xiaomi',
    'a4:77:33': 'Xiaomi',
    'ac:c1:ee': 'Xiaomi',
    'b0:e2:35': 'Xiaomi',
    'fc:64:ba': 'Xiaomi',

    // Huawei
    '00:18:82': 'Huawei',
    '00:1e:10': 'Huawei',
    '00:25:68': 'Huawei',
    '00:25:9e': 'Huawei',
    '00:34:fe': 'Huawei',
    '00:46:4b': 'Huawei',
    '00:66:4b': 'Huawei',
    '00:9a:cd': 'Huawei',
    '04:02:1f': 'Huawei',
    '04:25:c5': 'Huawei',
    '04:4f:4c': 'Huawei',
    '04:b0:e7': 'Huawei',
    '04:c0:6f': 'Huawei',
    '04:f9:38': 'Huawei',
    '08:19:a6': 'Huawei',
    '08:63:61': 'Huawei',
    '0c:37:dc': 'Huawei',

    // LG
    '00:05:c9': 'LG',
    '00:1c:62': 'LG',
    '00:1e:75': 'LG',
    '00:1f:6b': 'LG',
    '00:1f:e2': 'LG',
    '00:22:a9': 'LG',
    '00:24:83': 'LG',
    '00:25:e5': 'LG',
    '00:26:e2': 'LG',
    '10:68:3f': 'LG',
    '20:3d:bd': 'LG',
    '2c:54:cf': 'LG',
    '30:b4:9e': 'LG',
    '34:4d:f7': 'LG',
    '40:b8:9a': 'LG',
    '58:a2:b5': 'LG',
    '64:99:5d': 'LG',
    '88:c9:d0': 'LG',
    'a8:16:b2': 'LG',
    'a8:23:fe': 'LG',
    'ac:0d:1b': 'LG',
    'bc:f5:ac': 'LG',
    'c4:36:6c': 'LG',
    'cc:2d:8c': 'LG',

    // Tuya / Smart Life
    '10:d5:61': 'Tuya / Smart Life',
    '50:02:91': 'Tuya / Smart Life',
    '7c:f6:66': 'Tuya / Smart Life',
    '84:e3:42': 'Tuya / Smart Life',
    'd4:a6:51': 'Tuya / Smart Life',
    'd8:1f:12': 'Tuya / Smart Life',

    // Shelly
    '08:3a:f2': 'Shelly',
    '30:83:98': 'Shelly',

    // Ring (Amazon)
    '34:3e:a4': 'Ring (Amazon)',
    '4c:eb:42': 'Ring (Amazon)',
    'a8:b2:da': 'Ring (Amazon)',
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

  /// Looks up detailed vendor information by MAC address.
  static OuiVendorInfo? lookupMacDetailed(String? macAddress) {
    final name = lookupMac(macAddress);
    if (name == null) return null;
    return OuiVendorInfo(name: name);
  }
}
