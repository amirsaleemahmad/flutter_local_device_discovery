import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_device_discovery/flutter_local_device_discovery.dart';

/// A standalone runner that performs discovery and saves results to
/// `testResult.json`.
///
/// Run with:
/// ```
/// flutter run -d macos -t lib/discovery_runner.dart
/// ```
void main() {
  runApp(const DiscoveryRunnerApp());
}

class DiscoveryRunnerApp extends StatefulWidget {
  const DiscoveryRunnerApp({super.key});

  @override
  State<DiscoveryRunnerApp> createState() => _DiscoveryRunnerAppState();
}

class _DiscoveryRunnerAppState extends State<DiscoveryRunnerApp> {
  String _status = 'Starting...';
  String? _error;

  @override
  void initState() {
    super.initState();
    _runDiscovery();
  }

  Future<void> _runDiscovery() async {
    setState(() => _status = 'Initializing...');

    final discovery = FlutterLocalDeviceDiscovery();

    try {
      // Get capabilities
      setState(() => _status = 'Fetching capabilities...');
      final capabilities = await discovery.getCapabilities();
      debugPrint('Capabilities: ${capabilities.supportedProtocols}');

      // Run snapshot discovery
      setState(() => _status = 'Discovering devices for 15 seconds...');
      debugPrint('Starting discovery for 15 seconds...');
      final result = await discovery.discover(
        const LocalDiscoveryRequest(
          duration: Duration(seconds: 15),
          serviceTypes: {
            '_http._tcp',
            '_https._tcp',
            '_ipp._tcp',
            '_ipps._tcp',
            '_printer._tcp',
            '_pdl-datastream._tcp',
            '_scanner._tcp',
            '_airplay._tcp',
            '_raop._tcp',
            '_googlecast._tcp',
            '_googlezone._tcp',
            '_spotify-connect._tcp',
            '_sonos._tcp',
            '_ssh._tcp',
            '_smb._tcp',
            '_ftp._tcp',
            '_webdav._tcp',
            '_nfs._tcp',
            '_afpovertcp._tcp',
            '_rfb._tcp',
            '_companion-link._tcp',
            '_homekit._tcp',
            '_hap._tcp',
            '_mediaremotetv._tcp',
            '_touch-able._tcp',
            '_device-info._tcp',
            '_workstation._tcp',
            '_airport._tcp',
            '_adisk._tcp',
            '_sleep-proxy._udp',
            '_presence._tcp',
            '_tls._tcp',
          },
          resolveServices: true,
        ),
      );

      debugPrint('Discovery complete: ${result.devices.length} devices, '
          '${result.services.length} services');
      setState(() {
        _status = 'Discovery complete: ${result.devices.length} devices, '
            '${result.services.length} services. Saving results...';
      });

      // Build the JSON output
      final output = <String, Object?>{
        'timestamp': DateTime.now().toIso8601String(),
        'capabilities': {
          'supportedProtocols': capabilities.supportedProtocols
              .map((p) => p.name)
              .toList(),
          'supportsServiceRegistration':
              capabilities.supportsServiceRegistration,
          'supportsIpv4': capabilities.supportsIpv4,
          'supportsIpv6': capabilities.supportsIpv6,
          'supportsMultipleInterfaces':
              capabilities.supportsMultipleInterfaces,
          'requiresLocalNetworkPermission':
              capabilities.requiresLocalNetworkPermission,
          'requiresMulticastPermission':
              capabilities.requiresMulticastPermission,
          'platformDetails': capabilities.platformDetails,
        },
        'devices': result.devices.map((device) {
          return <String, Object?>{
            'id': device.id,
            'displayName': device.displayName,
            'hostname': device.hostname,
            'type': device.type.name,
            'addresses': device.addresses
                .map((a) => <String, Object?>{
                      'address': a.address,
                      'family': a.family,
                      'scopeId': a.scopeId,
                      'interfaceName': a.interfaceName,
                      'isLoopback': a.isLoopback,
                      'isLinkLocal': a.isLinkLocal,
                      'isPrivate': a.isPrivate,
                      'isMulticast': a.isMulticast,
                    })
                .toList(),
            'services': device.services.map((s) => s.serviceType).toList(),
            'discoveredBy': device.discoveredBy.map((p) => p.name).toList(),
            'firstSeenAt': device.firstSeenAt?.toIso8601String(),
            'lastSeenAt': device.lastSeenAt?.toIso8601String(),
            'confidence': device.confidence,
            'metadata': device.metadata,
          };
        }).toList(),
        'services': result.services.map((service) {
          return <String, Object?>{
            'id': service.id,
            'instanceName': service.instanceName,
            'serviceType': service.serviceType,
            'domain': service.domain,
            'hostname': service.hostname,
            'port': service.port,
            'transport': service.transport.name,
            'addresses': service.addresses
                .map((a) => <String, Object?>{
                      'address': a.address,
                      'family': a.family,
                      'scopeId': a.scopeId,
                      'interfaceName': a.interfaceName,
                    })
                .toList(),
            'textTxtRecords': service.textTxtRecords,
            'discoveredBy': service.discoveredBy.map((p) => p.name).toList(),
            'firstSeenAt': service.firstSeenAt?.toIso8601String(),
            'lastSeenAt': service.lastSeenAt?.toIso8601String(),
            'resolved': service.resolved,
            'location': service.location?.toString(),
            'metadata': service.metadata,
          };
        }).toList(),
        'summary': {
          'deviceCount': result.devices.length,
          'serviceCount': result.services.length,
          'startedAt': result.startedAt?.toIso8601String(),
          'completedAt': result.completedAt?.toIso8601String(),
        },
      };

      // Write to testResult.json
      final file = File('testResult.json');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(output),
      );

      debugPrint('Results saved to: ${file.absolute.path}');
      setState(() {
        _status = 'Results saved to ${file.absolute.path}';
      });
    } catch (e, stackTrace) {
      debugPrint('Discovery failed: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _error = 'Discovery failed: $e';
        _status = 'Failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discovery Test Runner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Discovery Test Runner')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_error == null)
                  const CircularProgressIndicator()
                else
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                const SizedBox(height: 16),
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}