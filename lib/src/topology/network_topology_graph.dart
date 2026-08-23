import '../models/local_device.dart';

/// A graph model of the local network topology.
class NetworkTopologyGraph {
  const NetworkTopologyGraph({
    this.gateway,
    this.nodes = const <NetworkNode>[],
    this.edges = const <NetworkEdge>[],
    this.subnet,
    this.builtAt,
  });

  /// The gateway node (router).
  final NetworkNode? gateway;

  /// All nodes in the topology.
  final List<NetworkNode> nodes;

  /// Edges connecting nodes.
  final List<NetworkEdge> edges;

  /// The subnet of this topology (e.g. '192.168.1.0/24').
  final String? subnet;

  /// When this topology was built.
  final DateTime? builtAt;

  /// Returns all nodes directly connected to the gateway.
  List<NetworkNode> get directlyConnectedDevices {
    if (gateway == null) return nodes;
    return edges
        .where((e) => e.sourceId == gateway!.id || e.targetId == gateway!.id)
        .map((e) => e.sourceId == gateway!.id ? e.targetId : e.sourceId)
        .map((id) => nodes.firstWhere((n) => n.id == id, orElse: () => nodes.first))
        .toList();
  }

  /// Returns devices in a specific subnet.
  List<NetworkNode> subnetDevices(String subnet) {
    return nodes.where((n) => n.subnet == subnet).toList();
  }

  /// Returns the hop count between two nodes (-1 if no path).
  int hopCount(String fromId, String toId) {
    if (fromId == toId) return 0;
    // BFS
    final visited = <String>{};
    final queue = <(String, int)>[(fromId, 0)];
    while (queue.isNotEmpty) {
      final (current, hops) = queue.removeAt(0);
      if (current == toId) return hops;
      if (visited.contains(current)) continue;
      visited.add(current);
      for (final edge in edges) {
        if (edge.sourceId == current && !visited.contains(edge.targetId)) {
          queue.add((edge.targetId, hops + 1));
        }
        if (edge.targetId == current && !visited.contains(edge.sourceId)) {
          queue.add((edge.sourceId, hops + 1));
        }
      }
    }
    return -1;
  }

  /// Creates a [NetworkTopologyGraph] from a JSON map.
  factory NetworkTopologyGraph.fromJson(Map<String, Object?> json) {
    return NetworkTopologyGraph(
      gateway: json['gateway'] != null ? NetworkNode.fromJson(json['gateway'] as Map<String, Object?>) : null,
      nodes: (json['nodes'] as List<dynamic>?)
              ?.map((e) => NetworkNode.fromJson(e as Map<String, Object?>))
              .toList() ??
          const <NetworkNode>[],
      edges: (json['edges'] as List<dynamic>?)
              ?.map((e) => NetworkEdge.fromJson(e as Map<String, Object?>))
              .toList() ??
          const <NetworkEdge>[],
      subnet: json['subnet'] as String?,
      builtAt: json['builtAt'] != null ? DateTime.tryParse(json['builtAt'] as String) : null,
    );
  }

  /// Converts this [NetworkTopologyGraph] to a JSON map.
  Map<String, Object?> toJson() {
    return {
      if (gateway != null) 'gateway': gateway?.toJson(),
      'nodes': nodes.map((n) => n.toJson()).toList(),
      'edges': edges.map((e) => e.toJson()).toList(),
      if (subnet != null) 'subnet': subnet,
      if (builtAt != null) 'builtAt': builtAt?.toIso8601String(),
    };
  }
}

/// A node in the network topology graph.
class NetworkNode {
  const NetworkNode({
    required this.id,
    this.device,
    this.role = NetworkNodeRole.endpoint,
    this.ipAddress,
    this.macAddress,
    this.hostname,
    this.subnet,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final LocalDevice? device;
  final NetworkNodeRole role;
  final String? ipAddress;
  final String? macAddress;
  final String? hostname;
  final String? subnet;
  final Map<String, Object?> metadata;

  /// Creates a [NetworkNode] from a JSON map.
  factory NetworkNode.fromJson(Map<String, Object?> json) {
    return NetworkNode(
      id: json['id'] as String,
      role: NetworkNodeRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => NetworkNodeRole.endpoint,
      ),
      ipAddress: json['ipAddress'] as String?,
      macAddress: json['macAddress'] as String?,
      hostname: json['hostname'] as String?,
      subnet: json['subnet'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?)?.cast<String, Object?>() ?? const <String, Object?>{},
    );
  }

  /// Converts this [NetworkNode] to a JSON map.
  Map<String, Object?> toJson() {
    return {
      'id': id,
      if (device != null) 'deviceId': device?.id,
      'role': role.name,
      if (ipAddress != null) 'ipAddress': ipAddress,
      if (macAddress != null) 'macAddress': macAddress,
      if (hostname != null) 'hostname': hostname,
      if (subnet != null) 'subnet': subnet,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }
}

/// An edge connecting two nodes.
class NetworkEdge {
  const NetworkEdge({
    required this.sourceId,
    required this.targetId,
    this.type = NetworkEdgeType.wired,
    this.latencyMs,
    this.metadata = const <String, Object?>{},
  });

  final String sourceId;
  final String targetId;
  final NetworkEdgeType type;
  final double? latencyMs;
  final Map<String, Object?> metadata;

  /// Creates a [NetworkEdge] from a JSON map.
  factory NetworkEdge.fromJson(Map<String, Object?> json) {
    return NetworkEdge(
      sourceId: json['sourceId'] as String,
      targetId: json['targetId'] as String,
      type: NetworkEdgeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NetworkEdgeType.wired,
      ),
      latencyMs: (json['latencyMs'] as num?)?.toDouble(),
      metadata: (json['metadata'] as Map<String, dynamic>?)?.cast<String, Object?>() ?? const <String, Object?>{},
    );
  }

  /// Converts this [NetworkEdge] to a JSON map.
  Map<String, Object?> toJson() {
    return {
      'sourceId': sourceId,
      'targetId': targetId,
      'type': type.name,
      if (latencyMs != null) 'latencyMs': latencyMs,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }
}

/// The role of a node in the network.
enum NetworkNodeRole {
  gateway,
  switch_,
  accessPoint,
  endpoint,
  unknown,
}

/// The type of a network edge.
enum NetworkEdgeType {
  wired,
  wireless,
  virtual_,
  unknown,
}
