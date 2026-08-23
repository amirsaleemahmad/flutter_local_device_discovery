#include "flutter_local_device_discovery_plugin.h"

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/event_stream_handler.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <winsock2.h>
#include <iphlpapi.h>
#include <ws2tcpip.h>
#include <windns.h>
#include <wlanapi.h>
#pragma comment(lib, "wlanapi.lib")

#include <chrono>
#include <memory>
#include <string>
#include <thread>
#include <vector>
#include <functional>

#pragma comment(lib, "ws2_32.lib")
#pragma comment(lib, "iphlpapi.lib")
#pragma comment(lib, "dnsapi.lib")

namespace flutter_local_device_discovery {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

// Event types matching the Dart-side enum.
constexpr int kEventDiscoveryStarted = 0;
constexpr int kEventDeviceAdded = 1;
constexpr int kEventDeviceUpdated = 2;
constexpr int kEventDeviceRemoved = 3;
constexpr int kEventServiceAdded = 4;
constexpr int kEventServiceUpdated = 5;
constexpr int kEventServiceRemoved = 6;
constexpr int kEventNetworkChanged = 7;
constexpr int kEventDiscoveryWarning = 8;
constexpr int kEventDiscoveryFailure = 9;
constexpr int kEventDiscoveryStopped = 10;

std::string Utf8FromWide(const std::wstring& wide) {
  if (wide.empty()) {
    return std::string();
  }
  int size = WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), -1, nullptr, 0,
                                 nullptr, nullptr);
  std::string result(size - 1, 0);
  WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), -1, &result[0], size, nullptr,
                      nullptr);
  return result;
}

std::wstring WideFromUtf8(const std::string& utf8) {
  if (utf8.empty()) {
    return std::wstring();
  }
  int size = MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, nullptr, 0);
  std::wstring result(size - 1, 0);
  MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, &result[0], size);
  return result;
}

int64_t NowMillis() {
  return std::chrono::duration_cast<std::chrono::milliseconds>(
             std::chrono::system_clock::now().time_since_epoch())
      .count();
}

}  // namespace

// Stream handler that manages the event sink.
class DiscoveryEventStreamHandler
    : public flutter::StreamHandler<flutter::EncodableValue> {
 public:
  DiscoveryEventStreamHandler() : sink_(nullptr) {}

  void EmitEvent(const EncodableValue& event) {
    if (sink_) {
      sink_->Success(event);
    }
  }

 protected:
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnListenInternal(
      const flutter::EncodableValue* arguments,
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& sink)
      override {
    sink_ = std::move(sink);
    return nullptr;
  }

  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnCancelInternal(const flutter::EncodableValue* arguments) override {
    sink_.reset();
    return nullptr;
  }

 private:
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink_;
};

// Forward declaration of callbacks
class DiscoverySession;
static VOID WINAPIV OnBrowseCallback(DWORD Status, PVOID pQueryContext,
                                     PDNS_RECORD pDnsRecord);
static VOID WINAPIV OnResolveCallback(DWORD Status, PVOID pQueryContext,
                                      PDNS_SERVICE_INSTANCE pInstance);

// A discovery session that performs DNS-SD browsing on Windows.
class DiscoverySession {
 public:
  DiscoverySession(std::string session_id,
                   std::vector<std::string> service_types,
                   DiscoveryEventStreamHandler* stream_handler)
      : session_id_(std::move(session_id)),
        service_types_(std::move(service_types)),
        stream_handler_(stream_handler),
        running_(false) {}

  ~DiscoverySession() { Stop(); }

  void Start() {
    if (running_) {
      return;
    }
    running = true;

    // Initialize Winsock.
    WSADATA wsa_data;
    if (WSAStartup(MAKEWORD(2, 2), &wsa_data) != 0) {
      running_ = false;
      return;
    }

    for (const auto& service_type : service_types_) {
      DNS_SERVICE_CANCEL cancel_handle = { 0 };
      DNS_SERVICE_BROWSE_REQUEST request = { 0 };
      request.Version = DNS_QUERY_REQUEST_VERSION1;
      request.InterfaceIndex = 0; // 0 = all interfaces
      
      std::string query_str = service_type + ".local";
      std::wstring query_wstr = WideFromUtf8(query_str);
      
      query_names_.push_back(query_wstr);
      request.QueryName = query_names_.back().c_str();
      request.pBrowseCallback = OnBrowseCallback;
      request.pQueryContext = this;

      DNS_STATUS status = DnsServiceBrowse(&request, &cancel_handle);
      if (status == DNS_REQUEST_PENDING) {
        cancel_handles_.push_back(cancel_handle);
      }
    }
  }

  void Stop() {
    if (!running_) {
      return;
    }
    running_ = false;
    for (auto& cancel_handle : cancel_handles_) {
      DnsServiceBrowseCancel(&cancel_handle);
    }
    cancel_handles_.clear();
    query_names_.clear();
    resolve_names_.clear();
    WSACleanup();
  }

  bool IsRunning() const { return running_; }

  void HandleBrowseResult(DWORD status, PDNS_RECORD record) {
    if (!running_ || status != 0 || record == nullptr) return;
    for (PDNS_RECORD curr = record; curr != nullptr; curr = curr->pNext) {
      if (curr->wType == DNS_TYPE_PTR) {
        std::wstring instance_name = curr->Data.PTR.pNameHost;
        ResolveService(instance_name);
      }
    }
  }

  void ResolveService(const std::wstring& instance_name) {
    DNS_SERVICE_RESOLVE_REQUEST request = { 0 };
    request.Version = DNS_QUERY_REQUEST_VERSION1;
    request.InterfaceIndex = 0;
    
    resolve_names_.push_back(instance_name);
    request.QueryName = resolve_names_.back().c_str();
    request.pResolveCallback = OnResolveCallback;
    request.pQueryContext = this;

    DNS_SERVICE_CANCEL cancel_handle = { 0 };
    DNS_STATUS status = DnsServiceResolve(&request, &cancel_handle);
    if (status == DNS_REQUEST_PENDING) {
      // Resolve completed natively
    }
  }

  void HandleResolveResult(DWORD status, PDNS_SERVICE_INSTANCE instance) {
    if (!running_ || status != 0 || instance == nullptr) return;

    std::string instance_name = Utf8FromWide(instance->pszInstanceName);
    std::string hostname = Utf8FromWide(instance->pszHostName);
    int port = instance->wPort;

    EncodableMap text_txt_records;
    for (DWORD i = 0; i < instance->dwPropertyCount; ++i) {
      std::string key = Utf8FromWide(instance->keys[i]);
      std::string val = Utf8FromWide(instance->values[i]);
      text_txt_records[EncodableValue(key)] = EncodableValue(val);
    }

    EncodableList address_list;
    if (instance->ip4Address != nullptr) {
      struct in_addr addr;
      addr.S_un.S_addr = *instance->ip4Address;
      char ip_str[INET_ADDRSTRLEN];
      if (inet_ntop(AF_INET, &addr, ip_str, sizeof(ip_str)) != nullptr) {
        EncodableMap addr_map;
        addr_map[EncodableValue("address")] = EncodableValue(std::string(ip_str));
        addr_map[EncodableValue("family")] = EncodableValue(0);
        addr_map[EncodableValue("isLoopback")] = EncodableValue(std::string(ip_str).rfind("127.", 0) == 0);
        addr_map[EncodableValue("isLinkLocal")] = EncodableValue(std::string(ip_str).rfind("169.254.", 0) == 0);
        addr_map[EncodableValue("isPrivate")] = EncodableValue(
            std::string(ip_str).rfind("10.", 0) == 0 ||
            std::string(ip_str).rfind("192.168.", 0) == 0 ||
            std::string(ip_str).rfind("172.16.", 0) == 0
        );
        addr_map[EncodableValue("isMulticast")] = EncodableValue(false);
        address_list.push_back(EncodableValue(addr_map));
      }
    }
    if (instance->ip6Address != nullptr) {
      struct in6_addr addr6;
      memcpy(&addr6, instance->ip6Address, sizeof(addr6));
      char ip6_str[INET6_ADDRSTRLEN];
      if (inet_ntop(AF_INET6, &addr6, ip6_str, sizeof(ip6_str)) != nullptr) {
        EncodableMap addr_map;
        addr_map[EncodableValue("address")] = EncodableValue(std::string(ip6_str));
        addr_map[EncodableValue("family")] = EncodableValue(1);
        addr_map[EncodableValue("isLoopback")] = EncodableValue(std::string(ip6_str) == "::1");
        addr_map[EncodableValue("isLinkLocal")] = EncodableValue(std::string(ip6_str).rfind("fe80", 0) == 0);
        addr_map[EncodableValue("isPrivate")] = EncodableValue(false);
        addr_map[EncodableValue("isMulticast")] = EncodableValue(false);
        address_list.push_back(EncodableValue(addr_map));
      }
    }

    std::string service_type = "";
    size_t protocol_pos = instance_name.find("._tcp");
    if (protocol_pos == std::string::npos) {
      protocol_pos = instance_name.find("._udp");
    }
    if (protocol_pos != std::string::npos) {
      size_t type_start = instance_name.rfind('.', protocol_pos - 1);
      if (type_start != std::string::npos) {
        service_type = instance_name.substr(type_start + 1, protocol_pos - type_start + 4);
      }
    }

    EncodableMap service_map;
    service_map[EncodableValue("id")] = EncodableValue(instance_name);
    service_map[EncodableValue("instanceName")] = EncodableValue(instance_name);
    service_map[EncodableValue("serviceType")] = EncodableValue(service_type);
    service_map[EncodableValue("domain")] = EncodableValue("local");
    service_map[EncodableValue("hostname")] = EncodableValue(hostname);
    service_map[EncodableValue("port")] = EncodableValue(port);
    service_map[EncodableValue("transport")] = EncodableValue(instance_name.find("._udp") != std::string::npos ? 1 : 0);
    service_map[EncodableValue("rawTxtRecords")] = EncodableValue(EncodableMap());
    service_map[EncodableValue("textTxtRecords")] = EncodableValue(text_txt_records);
    service_map[EncodableValue("protocols")] = EncodableValue(EncodableList{EncodableValue(1)});
    service_map[EncodableValue("resolved")] = EncodableValue(true);
    service_map[EncodableValue("addresses")] = EncodableValue(address_list);
    service_map[EncodableValue("metadata")] = EncodableValue(EncodableMap());

    EncodableMap event_map;
    event_map[EncodableValue("type")] = EncodableValue(kEventServiceAdded);
    event_map[EncodableValue("sessionId")] = EncodableValue(session_id_);
    event_map[EncodableValue("service")] = EncodableValue(service_map);

    if (stream_handler_) {
      stream_handler_->EmitEvent(EncodableValue(event_map));
    }
  }

 private:
  std::string session_id_;
  std::vector<std::string> service_types_;
  DiscoveryEventStreamHandler* stream_handler_;
  bool running_;
  std::vector<DNS_SERVICE_CANCEL> cancel_handles_;
  std::vector<std::wstring> query_names_;
  std::vector<std::wstring> resolve_names_;
};

// Represents a registered service advertised on Windows.
class RegisteredService {
 public:
  RegisteredService(std::wstring instance_name, std::wstring service_type, WORD port, EncodableMap txt_records)
      : instance_name_(instance_name), service_type_(service_type), port_(port), txt_records_(txt_records), registered_(false), pInstance_(nullptr) {
    memset(&cancel_handle_, 0, sizeof(cancel_handle_));
  }

  ~RegisteredService() { Unregister(); }

  DNS_STATUS Register() {
    if (registered_) return 0;

    std::vector<std::wstring> keys_w;
    std::vector<std::wstring> values_w;
    for (const auto& pair : txt_records_) {
      if (const auto* key_str = std::get_if<std::string>(&pair.first)) {
        keys_w.push_back(WideFromUtf8(*key_str));
        if (const auto* val_str = std::get_if<std::string>(&pair.second)) {
          values_w.push_back(WideFromUtf8(*val_str));
        } else if (const auto* val_bytes = std::get_if<std::vector<uint8_t>>(&pair.second)) {
          values_w.push_back(WideFromUtf8(std::string(val_bytes->begin(), val_bytes->end())));
        } else {
          values_w.push_back(L"");
        }
      }
    }

    std::vector<PCWSTR> keys;
    std::vector<PCWSTR> values;
    for (size_t i = 0; i < keys_w.size(); ++i) {
      keys.push_back(keys_w[i].c_str());
      values.push_back(values_w[i].c_str());
    }

    std::wstring full_name = instance_name_ + L"." + service_type_ + L".local";

    pInstance_ = DnsServiceConstructInstance(
        full_name.c_str(),
        nullptr, // local host
        nullptr,
        nullptr,
        port_,
        0, // all interfaces
        static_cast<DWORD>(keys.size()),
        keys.data(),
        values.data()
    );

    if (pInstance_ == nullptr) {
      return ERROR_OUTOFMEMORY;
    }

    DNS_SERVICE_REGISTER_REQUEST request = { 0 };
    request.Version = DNS_QUERY_REQUEST_VERSION1;
    request.InterfaceIndex = 0;
    request.pServiceInstance = pInstance_;
    request.pRegisterCallback = OnRegisterCallback;
    request.pQueryContext = this;

    DNS_STATUS status = DnsServiceRegister(&request, &cancel_handle_);
    if (status == DNS_REQUEST_PENDING || status == 0) {
      registered_ = true;
      return 0;
    }

    DnsServiceFreeInstance(pInstance_);
    pInstance_ = nullptr;
    return status;
  }

  void Unregister() {
    if (!registered_) return;
    registered_ = false;
    DnsServiceRegisterCancel(&cancel_handle_);
    if (pInstance_) {
      DnsServiceFreeInstance(pInstance_);
      pInstance_ = nullptr;
    }
  }

  void UpdateTxt(EncodableMap txt_records) {
    txt_records_ = txt_records;
    if (registered_) {
      Unregister();
      Register();
    }
  }

  static VOID WINAPIV OnRegisterCallback(DWORD Status, PVOID pQueryContext,
                                         PDNS_SERVICE_INSTANCE pInstance) {
  }

 private:
  std::wstring instance_name_;
  std::wstring service_type_;
  WORD port_;
  EncodableMap txt_records_;
  bool registered_;
  DNS_SERVICE_CANCEL cancel_handle_;
  PDNS_SERVICE_INSTANCE pInstance_;
};

static VOID WINAPIV OnBrowseCallback(DWORD Status, PVOID pQueryContext,
                                     PDNS_RECORD pDnsRecord) {
  if (pQueryContext == nullptr) return;
  auto* session = static_cast<DiscoverySession*>(pQueryContext);
  session->HandleBrowseResult(Status, pDnsRecord);
  if (pDnsRecord != nullptr) {
    DnsRecordListFree(pDnsRecord, DnsFreeRecordList);
  }
}

static VOID WINAPIV OnResolveCallback(DWORD Status, PVOID pQueryContext,
                                      PDNS_SERVICE_INSTANCE pInstance) {
  if (pQueryContext == nullptr) return;
  auto* session = static_cast<DiscoverySession*>(pQueryContext);
  session->HandleResolveResult(Status, pInstance);
  if (pInstance != nullptr) {
    DnsServiceFreeInstance(pInstance);
  }
}


class NativeWsDiscoveryEngine {
public:
  NativeWsDiscoveryEngine(std::string session_id, DiscoveryEventStreamHandler* stream_handler) 
    : session_id_(std::move(session_id)), stream_handler_(stream_handler), running_(false) {}
    
  ~NativeWsDiscoveryEngine() { Stop(); }
  
  void Start() {
    if (running_) return;
    running_ = true;
    thread_ = std::thread([this]() {
      SOCKET sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
      if (sock == INVALID_SOCKET) return;
      
      struct sockaddr_in local_addr;
      memset(&local_addr, 0, sizeof(local_addr));
      local_addr.sin_family = AF_INET;
      local_addr.sin_port = htons(3702);
      local_addr.sin_addr.s_addr = htonl(INADDR_ANY);
      
      bind(sock, (struct sockaddr*)&local_addr, sizeof(local_addr));
      
      struct ip_mreq mreq;
      mreq.imr_multiaddr.s_addr = inet_addr("239.255.255.250");
      mreq.imr_interface.s_addr = htonl(INADDR_ANY);
      setsockopt(sock, IPPROTO_IP, IP_ADD_MEMBERSHIP, (char*)&mreq, sizeof(mreq));
      
      const char* probe = "<?xml version=\"1.0\" encoding=\"utf-8\"?><soap:Envelope xmlns:soap=\"http://www.w3.org/2003/05/soap-envelope\" xmlns:wsa=\"http://schemas.xmlsoap.org/ws/2004/08/addressing\" xmlns:wsd=\"http://schemas.xmlsoap.org/ws/2005/04/discovery\"><soap:Header><wsa:To>urn:schemas-xmlsoap-org:ws:2005:04:discovery</wsa:To><wsa:Action>http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</wsa:Action><wsa:MessageID>urn:uuid:12345</wsa:MessageID></soap:Header><soap:Body><wsd:Probe/></soap:Body></soap:Envelope>";
      
      struct sockaddr_in dest;
      memset(&dest, 0, sizeof(dest));
      dest.sin_family = AF_INET;
      dest.sin_port = htons(3702);
      dest.sin_addr.s_addr = inet_addr("239.255.255.250");
      
      sendto(sock, probe, strlen(probe), 0, (struct sockaddr*)&dest, sizeof(dest));
      
      char buffer[8192];
      while (running_) {
        fd_set readfds;
        FD_ZERO(&readfds);
        FD_SET(sock, &readfds);
        
        struct timeval tv = {1, 0};
        int ret = select(0, &readfds, NULL, NULL, &tv);
        if (ret > 0) {
          struct sockaddr_in from;
          int fromlen = sizeof(from);
          int bytes = recvfrom(sock, buffer, sizeof(buffer) - 1, 0, (struct sockaddr*)&from, &fromlen);
          if (bytes > 0) {
            buffer[bytes] = 0;
            std::string data(buffer);
            
            std::string endpoint = "";
            size_t start = data.find("<wsa:Address>");
            if (start != std::string::npos) {
              start += 13;
              size_t end = data.find("</wsa:Address>", start);
              if (end != std::string::npos) {
                endpoint = data.substr(start, end - start);
              }
            }
            
            std::string types = "";
            size_t types_start = data.find("<wsd:Types>");
            if (types_start != std::string::npos) {
              types_start += 11;
              size_t types_end = data.find("</wsd:Types>", types_start);
              if (types_end != std::string::npos) {
                types = data.substr(types_start, types_end - types_start);
              }
            }
            
            std::string xaddrs = "";
            size_t xaddrs_start = data.find("<wsd:XAddrs>");
            if (xaddrs_start != std::string::npos) {
              xaddrs_start += 12;
              size_t xaddrs_end = data.find("</wsd:XAddrs>", xaddrs_start);
              if (xaddrs_end != std::string::npos) {
                xaddrs = data.substr(xaddrs_start, xaddrs_end - xaddrs_start);
              }
            }
            
            if (!endpoint.empty()) {
              using namespace flutter;
              EncodableMap service_map;
              service_map[EncodableValue("id")] = EncodableValue(session_id_ + ":" + endpoint);
              service_map[EncodableValue("endpointReference")] = EncodableValue(endpoint);
              service_map[EncodableValue("types")] = EncodableValue(types);
              service_map[EncodableValue("xAddrs")] = EncodableValue(xaddrs);
              service_map[EncodableValue("raw")] = EncodableValue(data);
              
              EncodableMap event_map;
              event_map[EncodableValue("type")] = EncodableValue(4);
              event_map[EncodableValue("sessionId")] = EncodableValue(session_id_);
              event_map[EncodableValue("protocol")] = EncodableValue(2);
              event_map[EncodableValue("service")] = EncodableValue(service_map);
              
              if (stream_handler_) {
                 stream_handler_->EmitEvent(EncodableValue(event_map));
              }
            }
          }
        }
      }
      
      closesocket(sock);
    });
  }
  
  void Stop() {
    running_ = false;
    if (thread_.joinable()) {
      thread_.join();
    }
  }
  
private:
  std::string session_id_;
  DiscoveryEventStreamHandler* stream_handler_;
  bool running_;
  std::thread thread_;
};

// static
void FlutterLocalDeviceDiscoveryPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "flutter_local_device_discovery",
      &flutter::StandardMethodCodec::GetInstance());

  auto event_stream_handler = std::make_unique<DiscoveryEventStreamHandler>();
  auto* raw_stream_handler = event_stream_handler.get();

  auto event_channel =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          registrar->messenger(), "flutter_local_device_discovery/events",
          &flutter::StandardMethodCodec::GetInstance());
  event_channel->SetStreamHandler(std::move(event_stream_handler));

  auto plugin = std::make_unique<FlutterLocalDeviceDiscoveryPlugin>(
      registrar, std::move(channel), raw_stream_handler);

  registrar->AddPlugin(std::move(plugin));
}

FlutterLocalDeviceDiscoveryPlugin::FlutterLocalDeviceDiscoveryPlugin(
    flutter::PluginRegistrarWindows* registrar,
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel,
    DiscoveryEventStreamHandler* stream_handler)
    : registrar_(registrar),
      channel_(std::move(channel)),
      stream_handler_(stream_handler) {
  channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) { HandleMethodCall(call, std::move(result)); });
}

FlutterLocalDeviceDiscoveryPlugin::~FlutterLocalDeviceDiscoveryPlugin() {
  if (ws_discovery_engine_) {
    delete static_cast<NativeWsDiscoveryEngine*>(ws_discovery_engine_);
  }
  sessions_.clear();
  registered_services_.clear();
}

void FlutterLocalDeviceDiscoveryPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = method_call.method_name();

  if (method == "getCapabilities") {
    HandleGetCapabilities(std::move(result));
  } else if (method == "checkReadiness") {
    HandleCheckReadiness(method_call, std::move(result));
  } else if (method == "startDiscovery") {
    HandleStartDiscovery(method_call, std::move(result));
  } else if (method == "pauseDiscovery" || method == "resumeDiscovery") {
    result->Success();
  } else if (method == "stopDiscovery") {
    HandleStopDiscovery(method_call, std::move(result));
  } else if (method == "getDiagnostics") {
    HandleGetDiagnostics(std::move(result));
  } else if (method == "registerService") {
    HandleRegisterService(method_call, std::move(result));
  } else if (method == "updateRegisteredService") {
    HandleUpdateRegisteredService(method_call, std::move(result));
  } else if (method == "unregisterService") {
    HandleUnregisterService(method_call, std::move(result));
  } else if (method == "startNativeSsdp") {
    HandleStartNativeSsdp(method_call, std::move(result));
  } else if (method == "stopNativeSsdp") {
    HandleStopNativeSsdp(method_call, std::move(result));
  } else if (method == "startNativeWsDiscovery") {
    HandleStartNativeWsDiscovery(method_call, std::move(result));
  } else if (method == "stopNativeWsDiscovery") {
    HandleStopNativeWsDiscovery(method_call, std::move(result));
  } else if (method == "getNetworkInfo") {
    HandleGetNetworkInfo(method_call, std::move(result));
  } else if (method == "getGatewayInfo") {
    HandleGetGatewayInfo(method_call, std::move(result));

  } else {
    result->NotImplemented();
  }
}

void FlutterLocalDeviceDiscoveryPlugin::HandleGetCapabilities(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  EncodableMap capabilities;
  capabilities[EncodableValue("supportedProtocols")] =
      EncodableValue(EncodableList{
          EncodableValue(0), // mdns
          EncodableValue(1), // dnsSd
          EncodableValue(2), // bonjour
      });
  capabilities[EncodableValue("supportsServiceRegistration")] =
      EncodableValue(true);
  capabilities[EncodableValue("supportsIpv4")] = EncodableValue(true);
  capabilities[EncodableValue("supportsIpv6")] = EncodableValue(true);
  capabilities[EncodableValue("supportsMultipleInterfaces")] =
      EncodableValue(true);
  capabilities[EncodableValue("supportsNetworkSpecificDiscovery")] =
      EncodableValue(false);
  capabilities[EncodableValue("supportsNeighborTable")] = EncodableValue(false);
  capabilities[EncodableValue("supportsReachability")] = EncodableValue(false);
  capabilities[EncodableValue("supportsSafePortProbe")] = EncodableValue(false);
  capabilities[EncodableValue("requiresLocalNetworkPermission")] =
      EncodableValue(false);
  capabilities[EncodableValue("requiresMulticastPermission")] =
      EncodableValue(false);
  capabilities[EncodableValue("platformDetails")] = EncodableValue(EncodableMap{
      {EncodableValue("windowsVersion"), EncodableValue("unknown")},
  });
  result->Success(EncodableValue(capabilities));
}

void FlutterLocalDeviceDiscoveryPlugin::HandleCheckReadiness(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  EncodableMap readiness;
  readiness[EncodableValue("canStart")] = EncodableValue(true);
  readiness[EncodableValue("requirements")] = EncodableValue(EncodableList());
  readiness[EncodableValue("warnings")] = EncodableValue(EncodableList());
  readiness[EncodableValue("platformDetails")] = EncodableValue(EncodableMap());
  result->Success(EncodableValue(readiness));
}

void FlutterLocalDeviceDiscoveryPlugin::HandleStartDiscovery(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* arguments = std::get_if<EncodableMap>(method_call.arguments());
  if (!arguments) {
    result->Error("invalid_configuration", "Arguments must be a map");
    return;
  }

  std::vector<std::string> service_types;
  auto service_types_it = arguments->find(EncodableValue("serviceTypes"));
  if (service_types_it != arguments->end()) {
    const auto* list = std::get_if<EncodableList>(&service_types_it->second);
    if (list) {
      for (const auto& item : *list) {
        if (const auto* str = std::get_if<std::string>(&item)) {
          service_types.push_back(*str);
        }
      }
    }
  }

  std::string session_id = "windows-" + std::to_string(NowMillis());
  auto session = std::make_unique<DiscoverySession>(session_id, service_types,
                                                    stream_handler_);
  session->Start();
  sessions_[session_id] = std::move(session);

  EncodableMap event_map;
  event_map[EncodableValue("type")] = EncodableValue(kEventDiscoveryStarted);
  event_map[EncodableValue("sessionId")] = EncodableValue(session_id);
  stream_handler_->EmitEvent(EncodableValue(event_map));

  result->Success(EncodableValue(session_id));
}

void FlutterLocalDeviceDiscoveryPlugin::HandleStopDiscovery(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* session_id = std::get_if<std::string>(method_call.arguments());
  if (session_id) {
    auto session_it = sessions_.find(*session_id);
    if (session_it != sessions_.end()) {
      session_it->second->Stop();
      sessions_.erase(session_it);
    }
    EncodableMap event_map;
    event_map[EncodableValue("type")] = EncodableValue(kEventDiscoveryStopped);
    event_map[EncodableValue("sessionId")] = EncodableValue(*session_id);
    stream_handler_->EmitEvent(EncodableValue(event_map));
  }
  result->Success();
}

void FlutterLocalDeviceDiscoveryPlugin::HandleGetDiagnostics(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  EncodableMap diagnostics;
  diagnostics[EncodableValue("pluginVersion")] = EncodableValue("0.3.0");
  diagnostics[EncodableValue("platformVersion")] = EncodableValue("windows");
  diagnostics[EncodableValue("supportedProtocols")] =
      EncodableValue(EncodableList{
          EncodableValue(0), // mdns
          EncodableValue(1), // dnsSd
          EncodableValue(2), // bonjour
      });
  diagnostics[EncodableValue("activeSessions")] =
      EncodableValue(static_cast<int>(sessions_.size()));
  diagnostics[EncodableValue("multicastAvailable")] = EncodableValue(true);
  diagnostics[EncodableValue("localNetworkReady")] = EncodableValue(true);
  diagnostics[EncodableValue("warnings")] = EncodableValue(EncodableList());
  diagnostics[EncodableValue("platformDetails")] = EncodableValue(EncodableMap());
  result->Success(EncodableValue(diagnostics));
}

void FlutterLocalDeviceDiscoveryPlugin::HandleRegisterService(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* arguments = std::get_if<EncodableMap>(method_call.arguments());
  if (!arguments) {
    result->Error("invalid_arguments", "Arguments must be a map");
    return;
  }

  std::string instance_name = "";
  if (auto it = arguments->find(EncodableValue("instanceName")); it != arguments->end()) {
    if (auto* str = std::get_if<std::string>(&it->second)) {
      instance_name = *str;
    }
  }

  std::string service_type = "";
  if (auto it = arguments->find(EncodableValue("serviceType")); it != arguments->end()) {
    if (auto* str = std::get_if<std::string>(&it->second)) {
      service_type = *str;
    }
  }

  int port = 0;
  if (auto it = arguments->find(EncodableValue("port")); it != arguments->end()) {
    if (auto* val = std::get_if<int>(&it->second)) {
      port = *val;
    } else if (auto* val = std::get_if<int64_t>(&it->second)) {
      port = static_cast<int>(*val);
    }
  }

  EncodableMap txt_records;
  if (auto it = arguments->find(EncodableValue("txtRecords")); it != arguments->end()) {
    if (auto* map = std::get_if<EncodableMap>(&it->second)) {
      txt_records = *map;
    }
  }

  std::string registration_id = "reg-" + std::to_string(NowMillis());
  auto service = std::make_unique<RegisteredService>(
      WideFromUtf8(instance_name), WideFromUtf8(service_type),
      static_cast<WORD>(port), txt_records);

  DNS_STATUS status = service->Register();
  if (status != 0) {
    result->Error("registration_failed", "Failed to register service: " + std::to_string(status));
    return;
  }

  registered_services_[registration_id] = std::move(service);

  EncodableMap response;
  response[EncodableValue("registrationId")] = EncodableValue(registration_id);
  response[EncodableValue("assignedName")] = EncodableValue(instance_name);
  response[EncodableValue("serviceType")] = EncodableValue(service_type);
  response[EncodableValue("port")] = EncodableValue(port);
  result->Success(EncodableValue(response));
}

void FlutterLocalDeviceDiscoveryPlugin::HandleUpdateRegisteredService(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* arguments = std::get_if<EncodableMap>(method_call.arguments());
  if (!arguments) {
    result->Error("invalid_arguments", "Arguments must be a map");
    return;
  }

  std::string registration_id = "";
  if (auto it = arguments->find(EncodableValue("registrationId")); it != arguments->end()) {
    if (auto* str = std::get_if<std::string>(&it->second)) {
      registration_id = *str;
    }
  }

  EncodableMap txt_records;
  if (auto it = arguments->find(EncodableValue("txtRecords")); it != arguments->end()) {
    if (auto* map = std::get_if<EncodableMap>(&it->second)) {
      txt_records = *map;
    }
  }

  auto service_it = registered_services_.find(registration_id);
  if (service_it != registered_services_.end()) {
    service_it->second->UpdateTxt(txt_records);
    result->Success();
  } else {
    result->Error("service_not_found", "Registered service not found");
  }
}

void FlutterLocalDeviceDiscoveryPlugin::HandleUnregisterService(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* registration_id = std::get_if<std::string>(method_call.arguments());
  if (!registration_id) {
    result->Error("invalid_arguments", "Argument must be a string");
    return;
  }

  auto service_it = registered_services_.find(*registration_id);
  if (service_it != registered_services_.end()) {
    service_it->second->Unregister();
    registered_services_.erase(service_it);
  }
  result->Success();
}

}  // namespace flutter_local_device_discovery
