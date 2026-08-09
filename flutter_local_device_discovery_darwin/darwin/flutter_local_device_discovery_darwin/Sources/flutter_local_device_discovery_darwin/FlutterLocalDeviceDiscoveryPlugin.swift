#if os(macOS)
import FlutterMacOS
#else
import Flutter
#endif
import Foundation
import Network

/// Formats a Date as an ISO 8601 string for the platform channel.
private func isoTimestamp(_ date: Date = Date()) -> String {
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
  return formatter.string(from: date)
}

/// The Apple platform implementation of flutter_local_device_discovery.
public class FlutterLocalDeviceDiscoveryPlugin: NSObject, FlutterPlugin {
  private var eventSink: FlutterEventSink?
  private var sessions: [String: DiscoverySession] = [:]
  private var registrations: [String: NWListener] = [:]
  private var pathMonitor: NWPathMonitor?
  private let pathMonitorQueue = DispatchQueue(label: "flutter_local_device_discovery.path_monitor")

  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(macOS)
    let messenger = registrar.messenger
    #else
    let messenger = registrar.messenger()
    #endif

    let channel = FlutterMethodChannel(
      name: "flutter_local_device_discovery",
      binaryMessenger: messenger
    )
    let eventChannel = FlutterEventChannel(
      name: "flutter_local_device_discovery/events",
      binaryMessenger: messenger
    )
    let instance = FlutterLocalDeviceDiscoveryPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance)
    registrar.addApplicationDelegate(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getCapabilities":
      handleGetCapabilities(result: result)
    case "checkReadiness":
      handleCheckReadiness(call: call, result: result)
    case "startDiscovery":
      handleStartDiscovery(call: call, result: result)
    case "pauseDiscovery":
      handlePauseDiscovery(call: call, result: result)
    case "resumeDiscovery":
      handleResumeDiscovery(call: call, result: result)
    case "stopDiscovery":
      handleStopDiscovery(call: call, result: result)
    case "registerService":
      handleRegisterService(call: call, result: result)
    case "updateRegisteredService":
      handleUpdateRegisteredService(call: call, result: result)
    case "unregisterService":
      handleUnregisterService(call: call, result: result)
    case "getDiagnostics":
      handleGetDiagnostics(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleGetCapabilities(result: @escaping FlutterResult) {
    result([
      "supportedProtocols": [0, 1, 2], // mdns, dnsSd, bonjour
      "supportsServiceRegistration": true,
      "supportsIpv4": true,
      "supportsIpv6": true,
      "supportsMultipleInterfaces": true,
      "supportsNetworkSpecificDiscovery": false,
      "supportsNeighborTable": false,
      "supportsReachability": false,
      "supportsSafePortProbe": false,
      "requiresLocalNetworkPermission": true,
      "requiresMulticastPermission": false,
      "platformDetails": [
        "osVersion": ProcessInfo.processInfo.operatingSystemVersionString,
      ],
    ])
  }

  private func handleCheckReadiness(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    let serviceTypes = args["serviceTypes"] as? [String] ?? []
    var requirements: [String] = []
    var warnings: [String] = []

    // Check if the app has NSLocalNetworkUsageDescription
    if Bundle.main.object(forInfoDictionaryKey: "NSLocalNetworkUsageDescription") == nil {
      requirements.append("local_network_description_missing")
    }

    // Check if Bonjour services are declared
    let declaredServices = Bundle.main.object(forInfoDictionaryKey: "NSBonjourServices") as? [String] ?? []
    for serviceType in serviceTypes {
      if !declaredServices.contains(serviceType) {
        warnings.append("bonjour_service_not_declared:\(serviceType)")
      }
    }

    result([
      "canStart": requirements.isEmpty,
      "requirements": requirements,
      "warnings": warnings,
      "platformDetails": [
        "hasLocalNetworkDescription": Bundle.main.object(forInfoDictionaryKey: "NSLocalNetworkUsageDescription") != nil,
        "declaredBonjourServices": declaredServices,
      ],
    ])
  }

  private func handleStartDiscovery(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    let sessionId = UUID().uuidString
    let serviceTypes = args["serviceTypes"] as? [String] ?? []
    let resolveServices = args["resolveServices"] as? Bool ?? true

    let session = DiscoverySession(
      sessionId: sessionId,
      serviceTypes: serviceTypes,
      resolveServices: resolveServices,
      onEvent: { [weak self] event in
        self?.emitEvent(event)
      }
    )

    sessions[sessionId] = session
    session.start()
    result(sessionId)
  }

  private func handlePauseDiscovery(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let sessionId = call.arguments as? String,
          let session = sessions[sessionId] else {
      result(FlutterError(code: "session_not_found", message: "No session found", details: nil))
      return
    }
    session.pause()
    result(nil)
  }

  private func handleResumeDiscovery(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let sessionId = call.arguments as? String,
          let session = sessions[sessionId] else {
      result(FlutterError(code: "session_not_found", message: "No session found", details: nil))
      return
    }
    session.resume()
    result(nil)
  }

  private func handleStopDiscovery(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let sessionId = call.arguments as? String else {
      result(nil)
      return
    }
    sessions.removeValue(forKey: sessionId)?.stop()
    result(nil)
  }

  private func handleRegisterService(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    guard let instanceName = args["instanceName"] as? String,
          let serviceType = args["serviceType"] as? String,
          let port = args["port"] as? Int else {
      result(FlutterError(code: "invalid_configuration", message: "instanceName, serviceType, and port are required", details: nil))
      return
    }

    let rawTxt = args["txtRecords"] as? [String: FlutterStandardTypedData] ?? [:]
    let txtMap = rawTxt.mapValues { String(data: $0.data, encoding: .utf8) ?? "" }

    do {
      let listener = try NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: UInt16(port))!)
      var txtRecord = NWTXTRecord()
      for (key, value) in txtMap {
        txtRecord[key] = value
      }

      listener.service = NWListener.Service(
        name: instanceName,
        type: serviceType,
        txtRecord: txtRecord
      )

      let registrationId = UUID().uuidString
      registrations[registrationId] = listener

      listener.stateUpdateHandler = { state in
        switch state {
        case .ready:
          result([
            "registrationId": registrationId,
            "assignedName": instanceName,
            "serviceType": serviceType,
            "port": port,
          ])
        case .failed(let error):
          self.registrations.removeValue(forKey: registrationId)
          result(FlutterError(code: "service_registration_failed", message: error.localizedDescription, details: nil))
        default:
          break
        }
      }

      listener.start(queue: .global(qos: .userInitiated))
    } catch {
      result(FlutterError(code: "service_registration_failed", message: error.localizedDescription, details: nil))
    }
  }

  private func handleUpdateRegisteredService(call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }

  private func handleUnregisterService(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let registrationId = call.arguments as? String else {
      result(nil)
      return
    }
    registrations.removeValue(forKey: registrationId)?.cancel()
    result(nil)
  }

  private func handleGetDiagnostics(result: @escaping FlutterResult) {
    result([
      "pluginVersion": "0.2.0",
      "platformVersion": ProcessInfo.processInfo.operatingSystemVersionString,
      "supportedProtocols": [0, 1, 2],
      "activeSessions": sessions.count,
      "multicastAvailable": true,
      "localNetworkReady": true,
      "warnings": [],
      "platformDetails": [
        "osVersion": ProcessInfo.processInfo.operatingSystemVersionString,
      ],
    ])
  }

  private func emitEvent(_ event: [String: Any]) {
    DispatchQueue.main.async {
      self.eventSink?(event)
    }
  }

  private func startPathMonitoring() {
    guard pathMonitor == nil else { return }
    let monitor = NWPathMonitor()
    monitor.pathUpdateHandler = { [weak self] path in
      self?.emitEvent([
        "type": 7, // LocalNetworkChanged
        "timestamp": isoTimestamp(),
      ])
    }
    monitor.start(queue: pathMonitorQueue)
    pathMonitor = monitor
  }
}

extension FlutterLocalDeviceDiscoveryPlugin: FlutterStreamHandler {
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    startPathMonitoring()
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    pathMonitor?.cancel()
    pathMonitor = nil
    return nil
  }
}

/// Extracts the Bonjour service type from an NWBrowser.Result.
private func bonjourServiceType(from result: NWBrowser.Result) -> String {
  switch result.endpoint {
  case .service(_, let type, _, _):
    return type
  default:
    return ""
  }
}

/// A single discovery session using Apple's Network framework.
class DiscoverySession {
  private let sessionId: String
  private let serviceTypes: [String]
  private let resolveServices: Bool
  private let onEvent: ([String: Any]) -> Void
  private var browsers: [NWBrowser] = []
  private var discoveredServiceTypes: Set<String> = []
  private var browsingServiceTypes: Set<String> = []
  private var paused = false
  private var stopped = false

  init(
    sessionId: String,
    serviceTypes: [String],
    resolveServices: Bool,
    onEvent: @escaping ([String: Any]) -> Void
  ) {
    self.sessionId = sessionId
    self.serviceTypes = serviceTypes
    self.resolveServices = resolveServices
    self.onEvent = onEvent
  }

  func start() {
    onEvent([
      "type": 0, // LocalDiscoveryStarted
      "sessionId": sessionId,
      "protocol": 2, // bonjour
      "timestamp": isoTimestamp(),
    ])

    // Browse only explicitly requested service types. Apple requires these
    // types to be declared in NSBonjourServices, and silently browsing every
    // type would violate the caller's request and privacy configuration.
    for serviceType in serviceTypes {
      startBrowsing(serviceType: serviceType)
    }
  }

  private func startBrowsing(serviceType: String) {
    guard !browsingServiceTypes.contains(serviceType) else { return }
    browsingServiceTypes.insert(serviceType)

    let parameters = NWParameters()
    parameters.includePeerToPeer = true
    let browser = NWBrowser(
      for: .bonjour(type: serviceType, domain: nil),
      using: parameters
    )

    browser.stateUpdateHandler = { [weak self] state in
      guard let self = self else { return }
      switch state {
      case .ready:
        break
      case .failed(let error):
        self.onEvent([
          "type": 9, // LocalDiscoveryFailure
          "sessionId": self.sessionId,
          "protocol": 2,
          "errorCode": "discovery_start_failed",
          "errorMessage": error.localizedDescription,
          "timestamp": isoTimestamp(),
        ])
      default:
        break
      }
    }

    browser.browseResultsChangedHandler = { [weak self] results, changes in
      self?.handleBrowseResultsChanged(results: results, changes: changes)
    }

    browser.start(queue: .global(qos: .userInitiated))
    browsers.append(browser)
  }

  private func handleMetaBrowseResultsChanged(
    results: Set<NWBrowser.Result>,
    changes: Set<NWBrowser.Result.Change>
  ) {
    guard !paused, !stopped else { return }
    print("Meta-browser results: \(results.count), changes: \(changes.count)")
    for result in results {
      switch result.endpoint {
      case .service(let name, let type, _, _):
        print("Meta-service found: name=\(name), type=\(type)")
      default:
        print("Meta-service endpoint: \(result.endpoint.debugDescription)")
      }
    }
    for change in changes {
      switch change {
      case .added(let result):
        // For the "_services._dns-sd._udp" meta-service, the instance name
        // IS the service type (e.g., "_airplay._tcp", "_http._tcp").
        let serviceType: String
        switch result.endpoint {
        case .service(let name, _, _, _):
          serviceType = name
        default:
          serviceType = ""
        }
        print("Meta-service added: \(serviceType)")
        if !serviceType.isEmpty && !discoveredServiceTypes.contains(serviceType) {
          discoveredServiceTypes.insert(serviceType)
          // Start browsing this newly discovered service type.
          startBrowsing(serviceType: serviceType)
        }
      default:
        break
      }
    }
  }

  private func handleBrowseResultsChanged(
    results: Set<NWBrowser.Result>,
    changes: Set<NWBrowser.Result.Change>
  ) {
    guard !paused, !stopped else { return }
    for change in changes {
      switch change {
      case .added(let result):
        handleAdded(result)
      case .removed(let result):
        handleRemoved(result)
      case .changed(let old, let new, _):
        handleChanged(old: old, new: new)
      default:
        break
      }
    }
  }

  func pause() {
    paused = true
  }

  func resume() {
    paused = false
  }

  func stop() {
    guard !stopped else { return }
    stopped = true
    browsers.forEach { $0.cancel() }
    browsers.removeAll()
    onEvent([
      "type": 10, // LocalDiscoveryStopped
      "sessionId": sessionId,
      "protocol": 2,
      "timestamp": isoTimestamp(),
    ])
  }

  private func handleAdded(_ result: NWBrowser.Result) {
    let now = isoTimestamp()
    let serviceTypeStr = bonjourServiceType(from: result)
    let instanceName: String
    switch result.endpoint {
    case .service(let name, _, _, _):
      instanceName = name
    default:
      instanceName = result.endpoint.debugDescription
    }

    let serviceMap: [String: Any] = [
      "id": "\(sessionId):\(result.endpoint.debugDescription)",
      "instanceName": instanceName,
      "serviceType": serviceTypeStr,
      "domain": "local.",
      "transport": 0,
      "protocols": [0, 1, 2],
      "firstSeenAt": now,
      "lastSeenAt": now,
    ]

    onEvent([
      "type": 4, // LocalServiceAdded
      "sessionId": sessionId,
      "protocol": 2,
      "service": serviceMap,
      "timestamp": now,
    ])

    // Also emit a device added event for the host of this service.
    let deviceId = "\(sessionId):\(instanceName)"
    let deviceMap: [String: Any] = [
      "id": deviceId,
      "displayName": instanceName,
      "hostname": instanceName,
      "type": 0, // unknown
      "protocols": [0, 1, 2],
      "services": [serviceMap],
      "firstSeenAt": now,
      "lastSeenAt": now,
    ]

    onEvent([
      "type": 1, // LocalDeviceAdded
      "sessionId": sessionId,
      "protocol": 2,
      "device": deviceMap,
      "timestamp": now,
    ])

    if resolveServices {
      resolve(result)
    }
  }

  private func handleRemoved(_ result: NWBrowser.Result) {
    let now = isoTimestamp()
    let serviceTypeStr = bonjourServiceType(from: result)
    let instanceName: String
    switch result.endpoint {
    case .service(let name, _, _, _):
      instanceName = name
    default:
      instanceName = result.endpoint.debugDescription
    }

    onEvent([
      "type": 6, // LocalServiceRemoved
      "sessionId": sessionId,
      "protocol": 2,
      "service": [
        "id": "\(sessionId):\(result.endpoint.debugDescription)",
        "instanceName": instanceName,
        "serviceType": serviceTypeStr,
        "domain": "local.",
        "transport": 0,
        "protocols": [0, 1, 2],
      ],
      "timestamp": now,
    ])

    // Also emit a device removed event.
    let deviceId = "\(sessionId):\(instanceName)"
    onEvent([
      "type": 3, // LocalDeviceRemoved
      "sessionId": sessionId,
      "protocol": 2,
      "device": [
        "id": deviceId,
        "displayName": instanceName,
        "hostname": instanceName,
        "type": 0,
        "protocols": [0, 1, 2],
      ],
      "timestamp": now,
    ])
  }

  private func handleChanged(old: NWBrowser.Result, new: NWBrowser.Result) {
    let now = isoTimestamp()
    let serviceTypeStr = bonjourServiceType(from: new)
    let instanceName: String
    switch new.endpoint {
    case .service(let name, _, _, _):
      instanceName = name
    default:
      instanceName = new.endpoint.debugDescription
    }

    onEvent([
      "type": 5, // LocalServiceUpdated
      "sessionId": sessionId,
      "protocol": 2,
      "service": [
        "id": "\(sessionId):\(new.endpoint.debugDescription)",
        "instanceName": instanceName,
        "serviceType": serviceTypeStr,
        "domain": "local.",
        "transport": 0,
        "protocols": [0, 1, 2],
        "lastSeenAt": now,
      ],
      "timestamp": now,
    ])

    // Also emit a device updated event.
    let deviceId = "\(sessionId):\(instanceName)"
    onEvent([
      "type": 2, // LocalDeviceUpdated
      "sessionId": sessionId,
      "protocol": 2,
      "device": [
        "id": deviceId,
        "displayName": instanceName,
        "hostname": instanceName,
        "type": 0,
        "protocols": [0, 1, 2],
        "lastSeenAt": now,
      ],
      "timestamp": now,
    ])
  }

  private func resolve(_ result: NWBrowser.Result) {
    // Try to resolve using a connection with IPv4 preference.
    let parameters = NWParameters.tcp
    let connection = NWConnection(to: result.endpoint, using: parameters)
    connection.stateUpdateHandler = { [weak self] state in
      guard let self = self else { return }
      switch state {
      case .ready:
        let now = isoTimestamp()
        var addresses: [[String: Any]] = []

        // Get the resolved address from the connection's remote endpoint.
        if let remoteEndpoint = connection.currentPath?.remoteEndpoint {
          switch remoteEndpoint {
          case .hostPort(let host, let port):
            let hostStr = "\(host)"
            let family = hostStr.contains(":") ? 6 : 4
            addresses.append([
              "address": hostStr,
              "family": family,
              "port": port.rawValue,
            ])
          default:
            break
          }
        }

        // Also try the result endpoint directly.
        if addresses.isEmpty {
          if case .hostPort(let host, let port) = result.endpoint {
            let hostStr = "\(host)"
            let family = hostStr.contains(":") ? 6 : 4
            addresses.append([
              "address": hostStr,
              "family": family,
              "port": port.rawValue,
            ])
          }
        }

        let serviceTypeStr = bonjourServiceType(from: result)
        let instanceName: String
        switch result.endpoint {
        case .service(let name, _, _, _):
          instanceName = name
        default:
          instanceName = result.endpoint.debugDescription
        }

        self.onEvent([
          "type": 5, // LocalServiceUpdated
          "sessionId": self.sessionId,
          "protocol": 2,
          "service": [
            "id": "\(self.sessionId):\(result.endpoint.debugDescription)",
            "instanceName": instanceName,
            "serviceType": serviceTypeStr,
            "domain": "local.",
            "addresses": addresses,
            "transport": 0,
            "protocols": [0, 1, 2],
            "resolved": true,
            "lastSeenAt": now,
          ],
          "timestamp": now,
        ])

        // Also emit a device updated event with the resolved address.
        let deviceId = "\(self.sessionId):\(instanceName)"
        self.onEvent([
          "type": 2, // LocalDeviceUpdated
          "sessionId": self.sessionId,
          "protocol": 2,
          "device": [
            "id": deviceId,
            "displayName": instanceName,
            "hostname": instanceName,
            "type": 0,
            "addresses": addresses,
            "protocols": [0, 1, 2],
            "lastSeenAt": now,
          ],
          "timestamp": now,
        ])
        connection.cancel()
      case .failed(let error):
        self.onEvent([
          "type": 9,
          "sessionId": self.sessionId,
          "protocol": 2,
          "errorCode": "service_resolution_failed",
          "errorMessage": error.localizedDescription,
          "timestamp": isoTimestamp(),
        ])
      default:
        break
      }
    }
    connection.start(queue: .global(qos: .userInitiated))
  }
}

