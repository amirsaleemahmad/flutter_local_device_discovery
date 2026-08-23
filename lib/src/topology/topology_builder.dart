import '../models/local_device.dart';
import '../models/local_device_type.dart';
import 'network_topology_graph.dart';

/// Builds a NetworkTopologyGraph from discovery results and gateway info.
class TopologyBuilder {
  const TopologyBuilder._();

  /// Builds a topology graph from a list of devices and optional gateway info.
  static NetworkTopologyGraph build({
    required List<LocalDevice> devices,
    String? gatewayAddress,
    String? subnet,
  }) {
    // 1. Find or create gateway node from gatewayAddress
    NetworkNode? gateway;
    if (gatewayAddress != null) {
      final gwDevice = devices.where((d) => d.ipv4Address?.address == gatewayAddress || d.addresses.any((a) => a.address == gatewayAddress)).firstOrNull;
      gateway = NetworkNode(
        id: gwDevice?.id ?? 'gateway_$gatewayAddress',
        device: gwDevice,
        role: NetworkNodeRole.gateway,
        ipAddress: gatewayAddress,
        subnet: subnet,
      );
    }

    // 2. Create NetworkNode for each device
    final nodes = <NetworkNode>[];
    if (gateway != null) {
      nodes.add(gateway);
    }

    for (final device in devices) {
      if (gateway != null && device.id == gateway.device?.id) {
        continue;
      }
      
      final role = _determineRole(device);
      
      nodes.add(
        NetworkNode(
          id: device.id,
          device: device,
          role: role,
          ipAddress: device.ipv4Address?.address ?? (device.addresses.isNotEmpty ? device.addresses.first.address : null),
          macAddress: device.identity.macAddress,
          hostname: device.hostname,
        ),
      );
    }

    // 4. Create edges from each device to gateway (star topology assumed)
    final edges = <NetworkEdge>[];
    if (gateway != null) {
      for (final node in nodes) {
        if (node.id != gateway.id) {
          edges.add(NetworkEdge(
            sourceId: node.id,
            targetId: gateway.id,
            type: NetworkEdgeType.unknown, // Need more info to know if wired or wireless
          ));
        }
      }
    }

    // 6. Return graph
    return NetworkTopologyGraph(
      gateway: gateway,
      nodes: nodes,
      edges: edges,
      subnet: subnet,
      builtAt: DateTime.now(),
    );
  }
  
  static NetworkNodeRole _determineRole(LocalDevice device) {
    if (device.type == LocalDeviceType.router || device.type == LocalDeviceType.gateway) {
      return NetworkNodeRole.gateway;
    } else if (device.type == LocalDeviceType.accessPoint) {
      return NetworkNodeRole.accessPoint;
    }
    return NetworkNodeRole.endpoint;
  }
}
