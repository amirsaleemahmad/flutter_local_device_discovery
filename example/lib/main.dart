import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_device_discovery/flutter_local_device_discovery.dart';
import 'package:flutter_local_device_discovery/testing.dart';

void main() => runApp(const DeviceDiscoveryApp());

class DeviceDiscoveryApp extends StatelessWidget {
  const DeviceDiscoveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Discovery v1.1 Review Console',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DiscoveryDashboard(),
    );
  }
}

class DiscoveryDashboard extends StatefulWidget {
  const DiscoveryDashboard({super.key});

  @override
  State<DiscoveryDashboard> createState() => _DiscoveryDashboardState();
}

class _DiscoveryDashboardState extends State<DiscoveryDashboard> {
  static const Set<String> _serviceTypes = <String>{
    '_http._tcp',
    '_https._tcp',
    '_ipp._tcp',
    '_ipps._tcp',
    '_printer._tcp',
    '_scanner._tcp',
    '_uscan._tcp',
    '_airplay._tcp',
    '_raop._tcp',
    '_googlecast._tcp',
    '_matter._tcp',
    '_hap._tcp',
    '_hue._tcp',
    '_spotify-connect._tcp',
    '_sonos._tcp',
    '_companion-link._tcp',
    '_device-info._tcp',
    '_ssh._tcp',
    '_smb._tcp',
    '_workstation._tcp',
  };

  final FlutterLocalDeviceDiscovery _discovery = FlutterLocalDeviceDiscovery();
  final Map<String, LocalDevice> _devices = <String, LocalDevice>{};
  final Map<String, LocalService> _services = <String, LocalService>{};
  final List<String> _eventLog = <String>[];
  final List<String> _warnings = <String>[];

  LocalDiscoveryCapabilities? _capabilities;
  LocalDiscoveryReadiness? _readiness;
  LocalDiscoveryDiagnostics? _diagnostics;
  LocalDiscoverySession? _session;
  StreamSubscription<LocalDiscoveryEvent>? _eventSubscription;
  bool _isDiscovering = false;
  bool _enableDnsSd = true;
  bool _enableSsdp = true;
  bool _enableWsDiscovery = true;
  bool _fetchUpnpDescriptions = true;
  int _durationSeconds = 10;
  String? _error;
  DateTime? _lastCompletedAt;

  List<NeighborTableEntry> _neighborEntries = <NeighborTableEntry>[];
  LocalServiceRegistrationResult? _registeredDemoService;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCapabilities());
    unawaited(_loadNeighborTable());
  }

  @override
  void dispose() {
    unawaited(_eventSubscription?.cancel());
    unawaited(_session?.stop());
    unawaited(_registeredDemoService?.stop());
    super.dispose();
  }

  Future<void> _loadCapabilities() async {
    try {
      final capabilities = await _discovery.getCapabilities();
      final diagnostics = await _discovery.getDiagnostics();
      if (!mounted) return;
      setState(() {
        _capabilities = capabilities;
        _diagnostics = diagnostics;
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = 'Capability check failed: $error');
    }
  }

  Future<void> _loadNeighborTable() async {
    try {
      final entries = await NeighborTable.getEntries();
      if (!mounted) return;
      setState(() {
        _neighborEntries = entries;
      });
    } on Object catch (_) {}
  }

  Future<void> _toggleDemoService() async {
    final handle = _registeredDemoService;
    if (handle != null) {
      await handle.stop();
      if (!mounted) return;
      setState(() {
        _registeredDemoService = null;
      });
      _log('Service unadvertised successfully.');
    } else {
      try {
        final newHandle = await _discovery.registerService(
          const LocalServiceRegistration(
            instanceName: 'Flutter Demo Service',
            serviceType: '_http._tcp',
            port: 8080,
            txtRecords: {
              'app': 'demo',
              'version': '1.0',
            },
          ),
        );
        if (!mounted) return;
        setState(() {
          _registeredDemoService = newHandle;
        });
        _log('Service advertised on port 8080.');
      } on Object catch (e) {
        _log('Failed to register service: $e');
      }
    }
  }

  Future<void> _checkMulticastHealth() async {
    _log('Checking multicast network health...');
    final isHealthy = await _discovery.checkMulticastHealth();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isHealthy
              ? 'Multicast health check PASSED: UDP multicast traffic is operational.'
              : 'Multicast health check WARNING: UDP multicast packets dropped or blocked by AP.',
        ),
        backgroundColor: isHealthy ? Colors.green : Colors.orange,
      ),
    );
    _log(
        'Multicast health check result: ${isHealthy ? "HEALTHY" : "DROPPED/BLOCKED"}');
  }

  Future<void> _probeAddress(String ip) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Probing reachability...'),
          ],
        ),
      ),
    );

    try {
      final result = await ReachabilityProber.probe(ip);
      if (!mounted) return;
      Navigator.of(context).pop();

      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Probe Result: $ip'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Status: ${result.status.name.toUpperCase()}'),
              const SizedBox(height: 8),
              if (result.lastCheckedAt != null)
                Text('Checked at: ${result.lastCheckedAt}'),
              if (result.latency != null)
                Text('Latency: ${result.latency!.inMilliseconds}ms'),
              if (result.successfulPort != null) ...<Widget>[
                Text('Successful Port: ${result.successfulPort}'),
                Text('Method: ${result.methods.join(", ")}'),
              ],
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Probe failed: $e')),
      );
    }
  }

  LocalDiscoveryRequest _buildRequest() {
    final protocols = <LocalDiscoveryProtocol>{};
    if (_enableDnsSd) {
      protocols
        ..add(LocalDiscoveryProtocol.mdns)
        ..add(LocalDiscoveryProtocol.dnsSd)
        ..add(LocalDiscoveryProtocol.bonjour);
    }
    if (_enableSsdp) {
      protocols
        ..add(LocalDiscoveryProtocol.ssdp)
        ..add(LocalDiscoveryProtocol.upnp);
    }
    if (_enableWsDiscovery) {
      protocols.add(LocalDiscoveryProtocol.wsDiscovery);
    }
    return LocalDiscoveryRequest(
      mode: LocalDiscoveryMode.servicesAndDevices,
      protocols: protocols,
      serviceTypes: _enableDnsSd ? _serviceTypes : const <String>{},
      ssdpSearchTargets:
          _enableSsdp ? const <String>{'ssdp:all'} : const <String>{},
      wsDiscoveryTypes: _enableWsDiscovery
          ? const <String>{'dn:NetworkVideoTransmitter'}
          : const <String>{},
      duration: Duration(seconds: _durationSeconds),
      resolveServices: true,
      fetchUpnpDescriptions: _enableSsdp && _fetchUpnpDescriptions,
      deduplicateResults: true,
      classifyDevices: true,
      metadataSecurityPolicy: MetadataSecurityPolicy.defaultPolicy,
    );
  }

  Future<void> _startDiscovery() async {
    if (_isDiscovering) return;
    if (kIsWeb) {
      setState(() {
        _error = 'Browsers cannot access mDNS or SSDP sockets. Run the example '
            'on Android, iOS, macOS, or Windows.';
      });
      return;
    }
    if (!_enableDnsSd && !_enableSsdp && !_enableWsDiscovery) {
      setState(() => _error = 'Enable at least one discovery protocol.');
      return;
    }

    final request = _buildRequest();
    setState(() {
      _isDiscovering = true;
      _error = null;
      _readiness = null;
      _devices.clear();
      _services.clear();
      _eventLog.clear();
      _warnings.clear();
    });

    LocalDiscoverySession? session;
    try {
      final readiness = await _discovery.checkReadiness(request);
      if (!mounted) return;
      setState(() {
        _readiness = readiness;
        _warnings.addAll(readiness.warnings);
      });
      if (!readiness.canStart) {
        throw StateError(
          'Discovery requirements are not met: '
          '${readiness.requirements.join(', ')}',
        );
      }

      session = await _discovery.start(request);
      _session = session;
      _eventSubscription = session.events.listen(_handleEvent);
      final snapshot = await session.snapshot();
      await _eventSubscription?.cancel();
      await session.stop();
      final diagnostics = await _discovery.getDiagnostics();

      if (!mounted) return;
      setState(() {
        _devices
          ..clear()
          ..addEntries(
            snapshot.devices.map((device) => MapEntry(device.id, device)),
          );
        _services
          ..clear()
          ..addEntries(
            snapshot.services.map((service) => MapEntry(service.id, service)),
          );
        _diagnostics = diagnostics;
        _lastCompletedAt = snapshot.completedAt;
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = 'Discovery failed: $error');
    } finally {
      await _eventSubscription?.cancel();
      if (session != null &&
          session.state != LocalDiscoverySessionState.stopped) {
        await session.stop();
      }
      if (mounted) {
        setState(() {
          _isDiscovering = false;
          _session = null;
          _eventSubscription = null;
        });
      }
    }
  }

  Future<void> _stopDiscovery() async {
    await _session?.stop();
  }

  void _handleEvent(LocalDiscoveryEvent event) {
    if (!mounted) return;
    setState(() {
      switch (event) {
        case LocalDiscoveryStarted():
          _log('Discovery engines started');
        case LocalDeviceAdded(:final device):
          _devices[device.id] = device;
          _log('Device added: ${device.displayName}');
        case LocalDeviceUpdated(:final device):
          _devices[device.id] = device;
          _log('Device enriched: ${device.displayName}');
        case LocalDeviceRemoved(:final device):
          _devices.remove(device.id);
          _log('Device removed: ${device.displayName}');
        case LocalServiceAdded(:final service):
          _services[service.id] = service;
          _log('Service added: ${service.serviceType}');
        case LocalServiceUpdated(:final service):
          _services[service.id] = service;
          _log('Service resolved: ${service.instanceName}');
        case LocalServiceRemoved(:final service):
          _services.remove(service.id);
          _log('Service removed: ${service.instanceName}');
        case LocalNetworkChanged():
          _log('Network configuration changed');
        case LocalDiscoveryWarning(:final message):
          if (!_warnings.contains(message)) _warnings.add(message);
          _log('Warning: $message');
        case LocalDiscoveryFailure(:final error):
          if (!_warnings.contains('$error')) _warnings.add('$error');
          _log('Engine failure: $error');
        case LocalDiscoveryStopped():
          _log('Discovery engines stopped');
      }
    });
  }

  void _loadDemoFixtures() {
    setState(() {
      for (final fixture in [
        DeviceFixtures.hpLaserJetPrinter,
        DeviceFixtures.appleTv,
        DeviceFixtures.philipsHueBridge,
        DeviceFixtures.onvifCamera,
      ]) {
        _devices[fixture.id] = fixture;
        for (final service in fixture.services) {
          _services[service.id] = service;
        }
      }
    });
    _log('Loaded 4 realistic demo Wi-Fi & Smart Home device fixtures.');
  }

  void _clearDevices() {
    setState(() {
      _devices.clear();
      _services.clear();
      _eventLog.clear();
    });
    _log('Cleared device lists.');
  }

  void _log(String message) {
    _eventLog.insert(0, '${_clock(DateTime.now())}  $message');
    if (_eventLog.length > 12) _eventLog.removeLast();
  }

  @override
  Widget build(BuildContext context) {
    final devices = _devices.values.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    final services = _services.values.toList()
      ..sort((a, b) => a.instanceName.compareTo(b.instanceName));
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Local Discovery'),
            Text('v1.1.0 review console', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: <Widget>[
          if (devices.isNotEmpty && !_isDiscovering)
            IconButton(
              onPressed: _clearDevices,
              tooltip: 'Clear devices',
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          IconButton(
            onPressed: _loadDemoFixtures,
            tooltip: 'Load demo Wi-Fi & IoT devices',
            icon: const Icon(Icons.devices_other),
          ),
          if (_isDiscovering)
            IconButton(
              onPressed: _stopDiscovery,
              tooltip: 'Stop discovery',
              icon: const Icon(Icons.stop_circle_outlined),
            )
          else
            IconButton(
              onPressed: _startDiscovery,
              tooltip: 'Start discovery',
              icon: const Icon(Icons.radar),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _isDiscovering ? () async {} : _startDiscovery,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _buildControlPanel(),
            if (_isDiscovering) ...<Widget>[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              _MessageCard(
                icon: Icons.error_outline,
                message: _error!,
                color: Theme.of(context).colorScheme.errorContainer,
              ),
            ],
            if (_warnings.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              _WarningsCard(warnings: _warnings),
            ],
            const SizedBox(height: 16),
            _buildSummary(devices),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Devices',
              count: devices.length,
              subtitle: 'Deduplicated across DNS-SD, SSDP, and UPnP',
            ),
            const SizedBox(height: 8),
            if (devices.isEmpty)
              const _EmptyCard(
                icon: Icons.devices_other,
                message: 'Start discovery to inspect normalized devices.',
              )
            else
              ...devices.map((device) => _DeviceCard(
                    device: device,
                    onProbeAddress: _probeAddress,
                  )),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'DNS-SD services',
              count: services.length,
              subtitle: 'Resolved ports, addresses, and TXT records',
            ),
            const SizedBox(height: 8),
            if (services.isEmpty)
              const _EmptyCard(
                icon: Icons.dns_outlined,
                message: 'No DNS-SD services observed yet.',
              )
            else
              ...services.map((service) => _ServiceCard(service: service)),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('ARP / Neighbor Table',
                          style: Theme.of(context).textTheme.titleLarge),
                      const Text('Local subnet IP/MAC cache (where permitted)',
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadNeighborTable,
                  tooltip: 'Refresh neighbor table',
                ),
                Badge(label: Text('${_neighborEntries.length}')),
              ],
            ),
            const SizedBox(height: 8),
            if (_neighborEntries.isEmpty)
              const _EmptyCard(
                icon: Icons.table_rows_outlined,
                message:
                    'No ARP table entries parsed. Note: Restricted on iOS, macOS, and Android 10+ due to OS security policies.',
              )
            else
              Card(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _neighborEntries.length,
                  itemBuilder: (context, index) {
                    final entry = _neighborEntries[index];
                    final vendor =
                        OuiVendorResolver.lookupMac(entry.macAddress);
                    return ListTile(
                      leading: const Icon(Icons.network_ping),
                      title: Text(entry.ipAddress),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'MAC: ${entry.macAddress} | Interface: ${entry.interfaceName}'),
                          if (vendor != null)
                            Text(
                              'Vendor (OUI): $vendor',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      trailing: FilledButton.tonal(
                        onPressed: () => _probeAddress(entry.ipAddress),
                        child: const Text('Probe'),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            _DiagnosticsCard(diagnostics: _diagnostics, eventLog: _eventLog),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    final capabilities = _capabilities;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  _isDiscovering ? Icons.radar : Icons.tune,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isDiscovering ? 'Discovery in progress' : 'Review setup',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _isDiscovering ? _stopDiscovery : _startDiscovery,
                  icon: Icon(_isDiscovering ? Icons.stop : Icons.play_arrow),
                  label: Text(_isDiscovering ? 'Stop' : 'Run'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilterChip(
                  selected: _enableDnsSd,
                  onSelected: _isDiscovering
                      ? null
                      : (value) => setState(() => _enableDnsSd = value),
                  avatar: const Icon(Icons.dns_outlined, size: 18),
                  label: const Text('mDNS / DNS-SD'),
                ),
                FilterChip(
                  selected: _enableSsdp,
                  onSelected: _isDiscovering
                      ? null
                      : (value) {
                          setState(() {
                            _enableSsdp = value;
                            if (!value) _fetchUpnpDescriptions = false;
                          });
                        },
                  avatar: const Icon(Icons.cast_connected, size: 18),
                  label: const Text('SSDP'),
                ),
                FilterChip(
                  selected: _enableWsDiscovery,
                  onSelected: _isDiscovering
                      ? null
                      : (value) => setState(() => _enableWsDiscovery = value),
                  avatar: const Icon(Icons.router_outlined, size: 18),
                  label: const Text('WS-Discovery'),
                ),
                FilterChip(
                  selected: _fetchUpnpDescriptions,
                  onSelected: !_enableSsdp || _isDiscovering
                      ? null
                      : (value) =>
                          setState(() => _fetchUpnpDescriptions = value),
                  avatar: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('UPnP metadata'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                const Text('Duration'),
                const SizedBox(width: 12),
                SegmentedButton<int>(
                  segments: const <ButtonSegment<int>>[
                    ButtonSegment<int>(value: 5, label: Text('5s')),
                    ButtonSegment<int>(value: 10, label: Text('10s')),
                    ButtonSegment<int>(value: 15, label: Text('15s')),
                  ],
                  selected: <int>{_durationSeconds},
                  onSelectionChanged: _isDiscovering
                      ? null
                      : (values) =>
                          setState(() => _durationSeconds = values.single),
                ),
              ],
            ),
            if (capabilities != null) ...<Widget>[
              const Divider(height: 24),
              Text(
                'Available: ${capabilities.supportedProtocols.map((item) => item.name).join(', ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (_readiness != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                _readiness!.canStart
                    ? 'Readiness check passed'
                    : 'Readiness requirements: '
                        '${_readiness!.requirements.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _readiness!.canStart
                          ? Colors.green
                          : Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
            if (_lastCompletedAt != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                'Last completed at ${_clock(_lastCompletedAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const Divider(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Network Health Check',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: _checkMulticastHealth,
                  icon: const Icon(Icons.health_and_safety_outlined, size: 16),
                  label: const Text('Test Multicast'),
                ),
              ],
            ),
            if (capabilities?.supportsServiceRegistration ?? false) ...<Widget>[
              const Divider(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _registeredDemoService != null
                          ? 'Advertising "Flutter Demo Service"'
                          : 'Service Advertising Demo',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _toggleDemoService,
                    icon: Icon(
                      _registeredDemoService != null
                          ? Icons.portable_wifi_off
                          : Icons.wifi_tethering,
                      size: 16,
                    ),
                    label: Text(
                      _registeredDemoService != null ? 'Stop Adv' : 'Start Adv',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(List<LocalDevice> devices) {
    final ssdpCount = devices
        .where(
          (device) => device.discoveredBy.contains(LocalDiscoveryProtocol.ssdp),
        )
        .length;
    final enrichedCount = devices
        .where(
          (device) => device.discoveredBy.contains(LocalDiscoveryProtocol.upnp),
        )
        .length;
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Row(
          children: <Widget>[
            _SummaryValue(label: 'Devices', value: '${devices.length}'),
            _SummaryValue(label: 'Services', value: '${_services.length}'),
            _SummaryValue(label: 'SSDP', value: '$ssdpCount'),
            _SummaryValue(label: 'Enriched', value: '$enrichedCount'),
          ],
        ),
      ),
    );
  }

  String _clock(DateTime time) => '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}:'
      '${time.second.toString().padLeft(2, '0')}';
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.subtitle,
  });

  final String title;
  final int count;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Badge(label: Text('$count')),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device, required this.onProbeAddress});

  final LocalDevice device;
  final void Function(String) onProbeAddress;

  @override
  Widget build(BuildContext context) {
    final identity = device.identity;
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(child: Icon(_iconFor(device.type))),
        title: Text(device.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (device.hostname != null) Text(device.hostname!),
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: <Widget>[
                _MiniChip(device.type.name),
                ...device.discoveredBy.map((item) => _MiniChip(item.name)),
              ],
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: <Widget>[
          _DetailRow(label: 'ID', value: device.id),
          if (device.addresses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 100,
                    child: Text(
                      'Addresses',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: device.addresses.map((item) {
                        return ActionChip(
                          avatar: const Icon(Icons.network_ping, size: 14),
                          label: Text(item.address),
                          onPressed: () => onProbeAddress(item.address),
                          tooltip: 'Click to probe reachability',
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          if (device.manufacturer != null)
            _DetailRow(label: 'Manufacturer', value: device.manufacturer!),
          if (device.model != null)
            _DetailRow(label: 'Model', value: device.model!),
          if (device.modelNumber != null)
            _DetailRow(label: 'Model Number', value: device.modelNumber!),
          if (identity.serialNumber != null)
            _DetailRow(label: 'Serial', value: identity.serialNumber!),
          if (identity.upnpUdn != null)
            _DetailRow(label: 'UPnP UDN', value: identity.upnpUdn!),
          if (identity.wsEndpointReference != null)
            _DetailRow(
              label: 'WS Endpoint',
              value: identity.wsEndpointReference!,
            ),
          if (device.protocolMetadata.isNotEmpty) ...<Widget>[
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Decoded IoT Metadata (v1.1)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 4),
            ...device.protocolMetadata.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                ),
              );
            }),
          ],
          if (device.metadata['ssdpLocation'] case final String location)
            _DetailRow(label: 'Description', value: location),
          if (device.metadata['ssdpSearchTarget'] case final String target)
            _DetailRow(label: 'SSDP target', value: target),
          if (device.metadata['ssdpServer'] case final String server)
            _DetailRow(label: 'SSDP server', value: server),
          if (device.metadata['wsTypes'] case final List<dynamic> types)
            _DetailRow(label: 'WS Types', value: types.join(', ')),
          if (device.metadata['wsScopes'] case final List<dynamic> scopes)
            _DetailRow(label: 'WS Scopes', value: scopes.join(', ')),
          if (device.metadata['wsXAddrs'] case final List<dynamic> xaddrs)
            _DetailRow(label: 'WS XAddrs', value: xaddrs.join(', ')),
          if (device.capabilities.isNotEmpty) ...<Widget>[
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Inferred capabilities',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: device.capabilities
                    .map((item) => Chip(label: Text(item.name)))
                    .toList(),
              ),
            ),
          ],
          if (device.capabilityEvidence.isNotEmpty) ...<Widget>[
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Capability evidence',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ...device.capabilityEvidence.map(
              (item) => _DetailRow(
                label: item.capability,
                value: '${(item.confidence * 100).round()}% · ${item.source}',
              ),
            ),
          ],
          if (device.services.isNotEmpty) ...<Widget>[
            const Divider(),
            _DetailRow(
              label: 'Services',
              value: device.services.map((item) => item.serviceType).join(', '),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(LocalDeviceType type) => switch (type) {
        LocalDeviceType.printer => Icons.print_outlined,
        LocalDeviceType.scanner => Icons.document_scanner_outlined,
        LocalDeviceType.camera => Icons.videocam_outlined,
        LocalDeviceType.smartTv ||
        LocalDeviceType.mediaRenderer =>
          Icons.tv_outlined,
        LocalDeviceType.mediaServer ||
        LocalDeviceType.nas =>
          Icons.storage_outlined,
        LocalDeviceType.router || LocalDeviceType.gateway => Icons.router,
        LocalDeviceType.computer ||
        LocalDeviceType.server =>
          Icons.computer_outlined,
        _ => Icons.devices_other,
      };
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final LocalService service;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: Icon(service.resolved ? Icons.dns : Icons.dns_outlined),
        title: Text(service.instanceName),
        subtitle: Text(service.serviceType),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: <Widget>[
          _DetailRow(label: 'Domain', value: service.domain),
          if (service.hostname != null)
            _DetailRow(label: 'Host', value: service.hostname!),
          if (service.port != null)
            _DetailRow(label: 'Port', value: '${service.port}'),
          _DetailRow(label: 'Resolved', value: service.resolved ? 'Yes' : 'No'),
          _DetailRow(
            label: 'Protocols',
            value: service.discoveredBy.map((item) => item.name).join(', '),
          ),
          if (service.addresses.isNotEmpty)
            _DetailRow(
              label: 'Addresses',
              value: service.addresses.map((item) => item.address).join(', '),
            ),
          if (service.textTxtRecords.isNotEmpty) ...<Widget>[
            const Divider(),
            ...service.textTxtRecords.entries.map(
              (item) => _DetailRow(label: item.key, value: item.value),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard({required this.diagnostics, required this.eventLog});

  final LocalDiscoveryDiagnostics? diagnostics;
  final List<String> eventLog;

  @override
  Widget build(BuildContext context) {
    final value = diagnostics;
    return Card(
      child: ExpansionTile(
        initiallyExpanded: eventLog.isNotEmpty,
        leading: const Icon(Icons.monitor_heart_outlined),
        title: const Text('Diagnostics and event log'),
        subtitle: Text(
          value == null
              ? 'No diagnostic snapshot yet'
              : '${value.rawObservationCount} observations · '
                  '${value.metadataFetchCount} metadata fetches',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: <Widget>[
          if (value != null) ...<Widget>[
            _DetailRow(
              label: 'Plugin',
              value: value.pluginVersion ?? 'unknown',
            ),
            _DetailRow(
              label: 'Raw observations',
              value: '${value.rawObservationCount}',
            ),
            _DetailRow(
              label: 'Deduplicated',
              value: '${value.deduplicatedDeviceCount}',
            ),
            _DetailRow(
              label: 'UPnP fetches',
              value: '${value.metadataFetchCount}',
            ),
            _DetailRow(
              label: 'Resolved services',
              value: '${value.resolutionSuccessCount}',
            ),
            _DetailRow(
              label: 'Dropped events',
              value: '${value.droppedEventCount}',
            ),
          ],
          if (eventLog.isNotEmpty) ...<Widget>[
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Latest events',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 6),
            ...eventLog.map(
              (item) => Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WarningsCard extends StatelessWidget {
  const _WarningsCard({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: ExpansionTile(
        leading: const Icon(Icons.warning_amber_outlined),
        title: Text(
          '${warnings.length} warning${warnings.length == 1 ? '' : 's'}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: warnings
            .map(
              (item) => Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text('• $item'),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 42, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 3),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
