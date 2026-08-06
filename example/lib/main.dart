import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_device_discovery/flutter_local_device_discovery.dart';

void main() {
  runApp(const DeviceDiscoveryApp());
}

class DeviceDiscoveryApp extends StatelessWidget {
  const DeviceDiscoveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Device Discovery',
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
  final _discovery = FlutterLocalDeviceDiscovery();
  final _serviceTypes = <String>{
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
  };

  List<LocalDevice> _devices = [];
  List<LocalService> _services = [];
  bool _isDiscovering = false;
  String? _error;
  LocalDiscoveryCapabilities? _capabilities;
  DateTime? _lastDiscoveryAt;
  final Duration _discoveryDuration = const Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _loadCapabilities();
  }

  Future<void> _loadCapabilities() async {
    try {
      final caps = await _discovery.getCapabilities();
      setState(() => _capabilities = caps);
    } catch (e) {
      setState(() => _error = 'Failed to load capabilities: $e');
    }
  }

  Future<void> _startDiscovery() async {
    if (kIsWeb) {
      setState(() {
        _error = 'Local device discovery is not supported on web. '
            'Please run this example on a native platform '
            '(Android, iOS, macOS, or Windows).';
        _isDiscovering = false;
      });
      return;
    }

    setState(() {
      _isDiscovering = true;
      _error = null;
      _devices = [];
      _services = [];
    });

    try {
      final result = await _discovery.discover(
        LocalDiscoveryRequest(
          duration: _discoveryDuration,
          serviceTypes: _serviceTypes,
          resolveServices: true,
        ),
      );

      if (!mounted) return;
      setState(() {
        _devices = result.devices;
        _services = result.services;
        _isDiscovering = false;
        _lastDiscoveryAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Discovery failed: $e';
        _isDiscovering = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Device Discovery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isDiscovering ? null : _startDiscovery,
            tooltip: 'Start discovery',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _startDiscovery,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatusCard(),
            if (_error != null) _buildErrorCard(),
            if (_isDiscovering) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Discovering for ${_discoveryDuration.inSeconds} seconds...',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildSummaryCard(),
            const SizedBox(height: 16),
            Text(
              'Devices (${_devices.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (_devices.isEmpty && !_isDiscovering)
              const _EmptyState(
                icon: Icons.devices_other,
                message: 'No devices found. Tap refresh to start discovery.',
              )
            else
              ..._devices.map((device) => _DeviceCard(device: device)),
            const SizedBox(height: 24),
            Text(
              'Services (${_services.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (_services.isEmpty && !_isDiscovering)
              const _EmptyState(
                icon: Icons.dns,
                message: 'No services found.',
              )
            else
              ..._services.map((service) => _ServiceCard(service: service)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final caps = _capabilities;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _isDiscovering ? Icons.sync : Icons.check_circle,
                  color: _isDiscovering ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(_isDiscovering ? 'Discovering...' : 'Ready'),
                if (_lastDiscoveryAt != null) ...[
                  const Spacer(),
                  Text(
                    'Last: ${_formatTime(_lastDiscoveryAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            if (caps != null) ...[
              const SizedBox(height: 8),
              Text(
                'Protocols: ${caps.supportedProtocols.map((p) => p.name).join(', ')}',
              ),
              Text('IPv4: ${caps.supportsIpv4 ? 'Yes' : 'No'}'),
              Text('IPv6: ${caps.supportsIpv6 ? 'Yes' : 'No'}'),
              Text(
                'Registration: ${caps.supportsServiceRegistration ? 'Yes' : 'No'}',
              ),
              if (caps.platformDetails.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Platform: ${caps.platformDetails.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (_devices.isEmpty && _services.isEmpty) return const SizedBox.shrink();
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryItem(
              icon: Icons.devices_other,
              label: 'Devices',
              value: '${_devices.length}',
            ),
            _SummaryItem(
              icon: Icons.dns,
              label: 'Services',
              value: '${_services.length}',
            ),
            _SummaryItem(
              icon: Icons.wifi_tethering,
              label: 'Protocols',
              value: '${_capabilities?.supportedProtocols.length ?? 0}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(_error!)),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});

  final LocalDevice device;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Icon(_deviceIcon(device.type)),
        ),
        title: Text(device.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (device.hostname != null) Text('Host: ${device.hostname}'),
            if (device.addresses.isNotEmpty)
              Text(
                'IP: ${device.addresses.map((a) => a.address).join(', ')}',
              ),
            if (device.services.isNotEmpty)
              Text(
                'Services: ${device.services.map((s) => s.serviceType).join(', ')}',
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  label: 'Type',
                  value: device.type.name,
                ),
                _DetailRow(
                  label: 'Discovered By',
                  value: device.discoveredBy.map((p) => p.name).join(', '),
                ),
                if (device.addresses.isNotEmpty) ...[
                  const Divider(),
                  Text(
                    'Addresses',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  ...device.addresses.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${a.address} (IPv${a.family})'
                        '${a.isLoopback ? ' [loopback]' : ''}'
                        '${a.isLinkLocal ? ' [link-local]' : ''}'
                        '${a.isPrivate ? ' [private]' : ''}'
                        '${a.isMulticast ? ' [multicast]' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
                if (device.services.isNotEmpty) ...[
                  const Divider(),
                  Text(
                    'Services',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  ...device.services.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${s.serviceType} (${s.instanceName})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
                if (device.firstSeenAt != null || device.lastSeenAt != null) ...[
                  const Divider(),
                  if (device.firstSeenAt != null)
                    _DetailRow(
                      label: 'First Seen',
                      value: _formatDateTime(device.firstSeenAt!),
                    ),
                  if (device.lastSeenAt != null)
                    _DetailRow(
                      label: 'Last Seen',
                      value: _formatDateTime(device.lastSeenAt!),
                    ),
                ],
                if (device.confidence > 0)
                  _DetailRow(
                    label: 'Confidence',
                    value: '${(device.confidence * 100).toStringAsFixed(0)}%',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _deviceIcon(LocalDeviceType type) {
    switch (type) {
      case LocalDeviceType.printer:
        return Icons.print;
      case LocalDeviceType.camera:
        return Icons.videocam;
      case LocalDeviceType.smartTv:
        return Icons.tv;
      case LocalDeviceType.speaker:
        return Icons.speaker;
      case LocalDeviceType.router:
        return Icons.router;
      case LocalDeviceType.nas:
        return Icons.storage;
      case LocalDeviceType.computer:
        return Icons.computer;
      case LocalDeviceType.mobileDevice:
        return Icons.phone_android;
      default:
        return Icons.devices_other;
    }
  }

  String _formatDateTime(DateTime time) {
    final local = time.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final LocalService service;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.dns),
        title: Text(service.instanceName),
        subtitle: Text('Type: ${service.serviceType}'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Domain', value: service.domain),
                if (service.port != null)
                  _DetailRow(label: 'Port', value: '${service.port}'),
                if (service.hostname != null)
                  _DetailRow(label: 'Host', value: service.hostname!),
                _DetailRow(
                  label: 'Transport',
                  value: service.transport.name,
                ),
                _DetailRow(
                  label: 'Resolved',
                  value: service.resolved ? 'Yes' : 'No',
                ),
                _DetailRow(
                  label: 'Discovered By',
                  value: service.discoveredBy.map((p) => p.name).join(', '),
                ),
                if (service.addresses.isNotEmpty) ...[
                  const Divider(),
                  Text(
                    'Addresses',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  ...service.addresses.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${a.address} (IPv${a.family})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
                if (service.textTxtRecords.isNotEmpty) ...[
                  const Divider(),
                  Text(
                    'TXT Records',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  ...service.textTxtRecords.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${e.key} = ${e.value}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
                if (service.firstSeenAt != null || service.lastSeenAt != null) ...[
                  const Divider(),
                  if (service.firstSeenAt != null)
                    _DetailRow(
                      label: 'First Seen',
                      value: _formatDateTime(service.firstSeenAt!),
                    ),
                  if (service.lastSeenAt != null)
                    _DetailRow(
                      label: 'Last Seen',
                      value: _formatDateTime(service.lastSeenAt!),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime time) {
    final local = time.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}