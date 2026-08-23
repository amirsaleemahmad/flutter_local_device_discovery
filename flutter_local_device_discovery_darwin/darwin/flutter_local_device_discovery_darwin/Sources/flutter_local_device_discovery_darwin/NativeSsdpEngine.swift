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
class NativeSsdpEngine {
    private var connectionGroup: NWConnectionGroup?
    private let eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    
    init(messenger: FlutterBinaryMessenger) {
        eventChannel = FlutterEventChannel(name: "flutter_local_device_discovery/native_ssdp_events", binaryMessenger: messenger)
        eventChannel?.setStreamHandler(SsdpStreamHandler(engine: self))
    }
    
    func setEventSink(_ sink: FlutterEventSink?) {
        self.eventSink = sink
    }
    
    func start() {
        do {
            let multicastGroup = try NWMulticastGroup(for: [
                .hostPort(host: "239.255.255.250", port: 1900)
            ])
            let params = NWParameters.udp
            let group = NWConnectionGroup(with: multicastGroup, using: params)
            
            group.setReceiveHandler(maximumMessageSize: 65535, rejectOversizedMessages: true) { [weak self] message, content, isComplete in
                guard let content = content, let str = String(data: content, encoding: .utf8) else { return }
                self?.handleReceivedData(str)
            }
            
            group.stateUpdateHandler = { state in
                print("SSDP connection group state: \(state)")
            }
            
            group.start(queue: .global(qos: .userInitiated))
            self.connectionGroup = group
            
            // Send M-SEARCH
            let msearch = "M-SEARCH * HTTP/1.1\r\nHost: 239.255.255.250:1900\r\nMan: \"ssdp:discover\"\r\nST: ssdp:all\r\nMX: 3\r\n\r\n"
            let data = msearch.data(using: .utf8)!
            group.send(content: data) { error in
                if let error = error {
                    print("Failed to send M-SEARCH: \(error)")
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
    
    private func handleReceivedData(_ data: String) {
        var headers: [String: String] = [:]
        let lines = data.components(separatedBy: "\r\n")
        for line in lines {
            if let colonIndex = line.firstIndex(of: ":") {
                let key = String(line[..<colonIndex]).trimmingCharacters(in: .whitespaces).uppercased()
                let value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                headers[key] = value
            }
        }
        
        let usn = headers["USN"] ?? UUID().uuidString
        let location = headers["LOCATION"] ?? ""
        let server = headers["SERVER"] ?? ""
        let st = headers["ST"] ?? headers["NT"] ?? ""
        
        let serviceMap: [String: Any] = [
            "id": usn,
            "instanceName": st.isEmpty ? usn : st,
            "serviceType": st,
            "domain": "local.",
            "transport": 1, // udp
            "protocols": [3], // ssdp
            "textTxtRecords": [
                "location": location,
                "server": server,
                "usn": usn,
                "st": st,
            ]
        ]
        
        DispatchQueue.main.async {
            self.eventSink?([
                "type": 4, // LocalServiceAdded / ServiceFound
                "protocol": 3, // SSDP
                "service": serviceMap,
                "metadata": [
                    "ssdpLocation": location,
                    "ssdpServer": server,
                    "ssdpSearchTarget": st,
                    "usn": usn,
                ]
            ])
        }
    }
}

@available(macOS 11.0, iOS 14.0, *)
class SsdpStreamHandler: NSObject, FlutterStreamHandler {
    weak var engine: NativeSsdpEngine?
    
    init(engine: NativeSsdpEngine) {
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
