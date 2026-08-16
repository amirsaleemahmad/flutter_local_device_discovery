/// Decoders for smart home and IoT protocol payloads (Matter, HomeKit HAP, Google Cast, AirPlay).
class IotProtocolDecoders {
  const IotProtocolDecoders._();

  /// Decodes Matter / Thread DNS-SD TXT record attributes (`_matter._tcp`, `_matterc._udp`).
  static Map<String, Object?> decodeMatterTxt(Map<String, String> txt) {
    final result = <String, Object?>{'protocol': 'matter'};

    // VP: Vendor ID and Product ID (e.g. 4447+24577 or 0xFFF1+0x8000)
    final vp = txt['VP'] ?? txt['vp'];
    if (vp != null) {
      final parts = vp.split('+');
      if (parts.isNotEmpty) result['vendorId'] = parts[0];
      if (parts.length > 1) result['productId'] = parts[1];
    }

    // CM: Commissioning Mode (0, 1, 2)
    final cm = txt['CM'] ?? txt['cm'];
    if (cm != null) {
      result['commissioningMode'] = int.tryParse(cm) ?? cm;
    }

    // D: Discriminator (12-bit)
    final d = txt['D'] ?? txt['d'];
    if (d != null) {
      result['discriminator'] = int.tryParse(d) ?? d;
    }

    // DT: Device Type ID
    final dt = txt['DT'] ?? txt['dt'];
    if (dt != null) {
      result['deviceType'] = int.tryParse(dt) ?? dt;
    }

    // DN: Device Name
    final dn = txt['DN'] ?? txt['dn'];
    if (dn != null) {
      result['deviceName'] = dn;
    }

    // SII / SAI: Sleepy End Device timing parameters
    final sii = txt['SII'] ?? txt['sii'];
    if (sii != null) result['sleepyIdleInterval'] = int.tryParse(sii) ?? sii;
    final sai = txt['SAI'] ?? txt['sai'];
    if (sai != null) result['sleepyActiveInterval'] = int.tryParse(sai) ?? sai;

    return result;
  }

  /// Decodes Apple HomeKit Accessory Protocol (HAP) TXT records (`_hap._tcp`).
  static Map<String, Object?> decodeHapTxt(Map<String, String> txt) {
    final result = <String, Object?>{'protocol': 'homekit_hap'};

    // md: Model name
    if (txt.containsKey('md')) result['model'] = txt['md'];

    // pv: Protocol version
    if (txt.containsKey('pv')) result['protocolVersion'] = txt['pv'];

    // id: Device ID / Pairing ID
    if (txt.containsKey('id')) result['deviceId'] = txt['id'];

    // c#: Configuration Number (triggers re-reading on change)
    if (txt.containsKey('c#')) {
      result['configNumber'] = int.tryParse(txt['c#']!) ?? txt['c#'];
    }

    // s#: Current State Number
    if (txt.containsKey('s#')) {
      result['stateNumber'] = int.tryParse(txt['s#']!) ?? txt['s#'];
    }

    // sf: Status Flags (1 = not paired / pairing mode)
    if (txt.containsKey('sf')) {
      final sfInt = int.tryParse(txt['sf']!);
      result['statusFlags'] = sfInt ?? txt['sf'];
      result['isUnpaired'] = sfInt == 1;
    }

    // ci: Category Identifier (1: Other, 2: Bridge, 5: Lightbulb, 8: Switch, etc.)
    if (txt.containsKey('ci')) {
      final ciInt = int.tryParse(txt['ci']!);
      result['categoryIdentifier'] = ciInt ?? txt['ci'];
      result['categoryName'] = _hapCategoryName(ciInt);
    }

    // ff: Feature Flags
    if (txt.containsKey('ff')) {
      result['featureFlags'] = int.tryParse(txt['ff']!) ?? txt['ff'];
    }

    return result;
  }

  /// Decodes Google Cast DNS-SD TXT records (`_googlecast._tcp`).
  static Map<String, Object?> decodeGoogleCastTxt(Map<String, String> txt) {
    final result = <String, Object?>{'protocol': 'google_cast'};

    // fn: Friendly Name
    if (txt.containsKey('fn')) result['friendlyName'] = txt['fn'];

    // md: Model Name
    if (txt.containsKey('md')) result['modelName'] = txt['md'];

    // id: Device UUID
    if (txt.containsKey('id')) result['castId'] = txt['id'];

    // rs: Display Resolution capability
    if (txt.containsKey('rs')) result['resolution'] = txt['rs'];

    // ca: Capabilities bitmask (e.g. 4101 = Audio+Video+Display)
    if (txt.containsKey('ca')) {
      final caInt = int.tryParse(txt['ca']!);
      result['capabilitiesBitmask'] = caInt ?? txt['ca'];
      if (caInt != null) {
        result['supportsVideoOut'] = (caInt & 0x01) != 0;
        result['supportsVideoIn'] = (caInt & 0x02) != 0;
        result['supportsAudioOut'] = (caInt & 0x04) != 0;
        result['supportsAudioIn'] = (caInt & 0x08) != 0;
      }
    }

    // ic: Icon path
    if (txt.containsKey('ic')) result['iconPath'] = txt['ic'];

    // rm: Receiver model / firmware
    if (txt.containsKey('rm')) result['receiverModel'] = txt['rm'];

    // st: Setup status (1 = needs setup, 0 = configured)
    if (txt.containsKey('st')) {
      result['needsSetup'] = txt['st'] == '1';
    }

    return result;
  }

  /// Decodes Apple AirPlay DNS-SD TXT records (`_airplay._tcp`, `_raop._tcp`).
  static Map<String, Object?> decodeAirPlayTxt(Map<String, String> txt) {
    final result = <String, Object?>{'protocol': 'airplay'};

    // model: Device Model
    if (txt.containsKey('model')) result['model'] = txt['model'];

    // srcvers: Source / OS version
    if (txt.containsKey('srcvers')) result['sourceVersion'] = txt['srcvers'];

    // flags: Feature flags
    if (txt.containsKey('flags')) result['flags'] = txt['flags'];

    // pk: Public Encryption Key
    if (txt.containsKey('pk')) result['publicKey'] = txt['pk'];

    // pi: Pair Identity UUID
    if (txt.containsKey('pi')) result['pairingId'] = txt['pi'];

    // features: Extended features bitmask
    if (txt.containsKey('features')) result['features'] = txt['features'];

    return result;
  }

  static String _hapCategoryName(int? ci) {
    return switch (ci) {
      1 => 'Other',
      2 => 'Bridge',
      3 => 'Fan',
      4 => 'Garage Door Opener',
      5 => 'Lighting',
      6 => 'Lock',
      7 => 'Outlet',
      8 => 'Switch',
      9 => 'Thermostat',
      10 => 'Sensor',
      11 => 'Security System',
      12 => 'Door',
      13 => 'Window',
      14 => 'Window Covering',
      15 => 'Programmable Switch',
      16 => 'Range Extender',
      17 => 'IP Camera',
      18 => 'Video Doorbell',
      19 => 'Air Purifier',
      20 => 'Heater',
      21 => 'Air Conditioner',
      22 => 'Humidifier',
      23 => 'Dehumidifier',
      24 => 'Apple TV',
      28 => 'Sprinkler',
      29 => 'Faucet',
      30 => 'Shower Head',
      31 => 'Television',
      32 => 'Target Controller',
      33 => 'Wi-Fi Router',
      34 => 'Audio Receiver',
      _ => 'Smart Accessory',
    };
  }
}
