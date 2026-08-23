import Foundation
import Network
#if os(macOS)
import CoreWLAN
import FlutterMacOS
#elseif os(iOS)
import NetworkExtension
import Flutter
#endif

@available(macOS 11.0, iOS 14.0, *)
class NativeWsDiscoveryEngine: NSObject, XMLParserDelegate {
    private var connectionGroup: NWConnectionGroup?
    private let eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    
    // For XML parsing
    private var currentElement = ""
    private var currentEndpointReference = ""
    private var currentTypes = ""
    private var currentScopes = ""
    private var currentXAddrs = ""
    private var foundAddress = ""
    
    init(messenger: FlutterBinaryMessenger) {
        eventChannel = FlutterEventChannel(name: "flutter_local_device_discovery/native_ws_discovery_events", binaryMessenger: messenger)
        super.init()
        eventChannel?.setStreamHandler(WsDiscoveryStreamHandler(engine: self))
    }
    
    func setEventSink(_ sink: FlutterEventSink?) {
        self.eventSink = sink
    }
    
    func start() {
        do {
            let multicastGroup = try NWMulticastGroup(for: [
                .hostPort(host: "239.255.255.250", port: 3702)
            ])
            let params = NWParameters.udp
            let group = NWConnectionGroup(with: multicastGroup, using: params)
            
            group.setReceiveHandler(maximumMessageSize: 65535, rejectOversizedMessages: true) { [weak self] message, content, isComplete in
                guard let content = content, let self = self else { return }
                self.handleReceivedData(content)
            }
            
            group.stateUpdateHandler = { state in
                print("WS-Discovery connection group state: \(state)")
            }
            
            group.start(queue: .global(qos: .userInitiated))
            self.connectionGroup = group
            
            let uuid = UUID().uuidString
            let probeXml = """
                <?xml version="1.0" encoding="utf-8"?>
                <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsd="http://schemas.xmlsoap.org/ws/2005/04/discovery">
                  <soap:Header>
                    <wsa:To>urn:schemas-xmlsoap-org:ws:2005:04:discovery</wsa:To>
                    <wsa:Action>http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</wsa:Action>
                    <wsa:MessageID>urn:uuid:\(uuid)</wsa:MessageID>
                  </soap:Header>
                  <soap:Body>
                    <wsd:Probe/>
                  </soap:Body>
                </soap:Envelope>
            """
            
            let data = probeXml.data(using: .utf8)!
            group.send(content: data) { error in
                if let error = error {
                    print("Failed to send Probe: \(error)")
                }
            }
        } catch {
            print("Failed to create NWMulticastGroup: \(error)")
        }
    }
    
    func stop() {
        connectionGroup?.cancel()
        connectionGroup = nil
    }
    
    private func handleReceivedData(_ data: Data) {
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        currentEndpointReference = ""
        currentTypes = ""
        currentScopes = ""
        currentXAddrs = ""
        foundAddress = ""
        
        parser.parse()
        
        if !foundAddress.isEmpty {
            let str = String(data: data, encoding: .utf8) ?? ""
            let serviceMap: [String: Any] = [
                "id": foundAddress,
                "instanceName": currentTypes.isEmpty ? foundAddress : currentTypes,
                "serviceType": currentTypes,
                "domain": "local.",
                "transport": 1, // udp
                "protocols": [5], // wsDiscovery
                "textTxtRecords": [
                    "endpointReference": foundAddress,
                    "types": currentTypes,
                    "scopes": currentScopes,
                    "xAddrs": currentXAddrs,
                ]
            ]
            
            DispatchQueue.main.async {
                self.eventSink?([
                    "type": 4, // LocalServiceAdded
                    "protocol": 5, // WS-Discovery
                    "service": serviceMap,
                    "metadata": [
                        "wsEndpointReference": self.foundAddress,
                        "wsTypes": self.currentTypes,
                        "wsScopes": self.currentScopes,
                        "wsXAddrs": self.currentXAddrs,
                        "raw": str,
                    ]
                ])
            }
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        let normalizedElement = elementName.components(separatedBy: ":").last ?? elementName
        currentElement = normalizedElement
        if normalizedElement == "Address" {
            currentEndpointReference = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return }
        
        if currentElement == "Address" {
            currentEndpointReference += string
        } else if currentElement == "Types" {
            currentTypes += string
        } else if currentElement == "Scopes" {
            currentScopes += string
        } else if currentElement == "XAddrs" {
            currentXAddrs += string
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let normalizedElement = elementName.components(separatedBy: ":").last ?? elementName
        if normalizedElement == "Address" {
            foundAddress = currentEndpointReference.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if normalizedElement == "Types" {
            currentTypes = currentTypes.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if normalizedElement == "Scopes" {
            currentScopes = currentScopes.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if normalizedElement == "XAddrs" {
            currentXAddrs = currentXAddrs.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        currentElement = ""
    }
}

@available(macOS 11.0, iOS 14.0, *)
class WsDiscoveryStreamHandler: NSObject, FlutterStreamHandler {
    weak var engine: NativeWsDiscoveryEngine?
    
    init(engine: NativeWsDiscoveryEngine) {
        self.engine = engine
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        engine?.setEventSink(events)
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        engine?.setEventSink(nil)
        return nil
    }
}
