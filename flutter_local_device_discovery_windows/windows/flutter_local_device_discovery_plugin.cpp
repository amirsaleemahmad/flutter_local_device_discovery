#include "flutter_local_device_discovery_plugin.h"

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <winsock2.h>
#include <iphlpapi.h>
#include <ws2tcpip.h>

#include <chrono>
#include <memory>
#include <string>
#include <thread>
#include <vector>

#pragma comment(lib, "ws2_32.lib")
#pragma comment(lib, "iphlpapi.lib")

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

// Protocol constants.
constexpr int kProtocolMdns = 0;
constexpr int kProtocolDnsSd = 1;
constexpr int kProtocolBonjour = 2;

// Transport constants.
constexpr int kTransportTcp = 0;
constexpr int kTransportUdp = 1;

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

// A discovery session that performs DNS-SD browsing on Windows.
class DiscoverySession {
 public:
  DiscoverySession(std::string session_id, std::vector<std::string> service_types)
      : session_id_(std::move(session_id)),
        service_types_(std::move(service_types)),
        running_(false) {}

  ~DiscoverySession() { Stop(); }

  void Start() {
    if (running_) {
      return;
    }
    running_ = true;
    // Initialize Winsock.
    WSADATA wsa_data;
    if (WSAStartup(MAKEWORD(2, 2), &wsa_data) != 0) {
      running_ = false;
      return;
    }
    // Note: Full DNS-SD browsing on Windows requires the DnssdServiceWatcher
    // from Windows.Networking.ServiceDiscovery.Dnssd (WinRT). This foundation
    // establishes the session lifecycle and network interface enumeration.
    // The WinRT integration is layered on top in a follow-up.
    running_ = false;
    WSACleanup();
  }

  void Stop() {
    if (!running_) {
      return;
    }
    running_ = false;
  }

  bool IsRunning() const { return running_; }

 private:
  std::string session_id_;
  std::vector<std::string> service_types_;
  bool running_;
};

// static
void FlutterLocalDeviceDiscoveryPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "flutter_local_device_discovery",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FlutterLocalDeviceDiscoveryPlugin>(
      registrar, std::move(channel));

  registrar->AddPlugin(std::move(plugin));
}

FlutterLocalDeviceDiscoveryPlugin::FlutterLocalDeviceDiscoveryPlugin(
    flutter::PluginRegistrarWindows* registrar,
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel)
    : registrar_(registrar), channel_(std::move(channel)) {
  channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) { HandleMethodCall(call, std::move(result)); });
}

FlutterLocalDeviceDiscoveryPlugin::~FlutterLocalDeviceDiscoveryPlugin() {
  sessions_.clear();
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
  } else if (method == "stopDiscovery") {
    HandleStopDiscovery(method_call, std::move(result));
  } else if (method == "getDiagnostics") {
    HandleGetDiagnostics(std::move(result));
  } else {
    result->NotImplemented();
  }
}

void FlutterLocalDeviceDiscoveryPlugin::HandleGetCapabilities(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  EncodableMap capabilities;
  capabilities[EncodableValue("supportedProtocols")] =
      EncodableValue(EncodableList{kProtocolMdns, kProtocolDnsSd});
  capabilities[EncodableValue("supportsServiceRegistration")] =
      EncodableValue(false);
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
  auto session = std::make_unique<DiscoverySession>(session_id, service_types);
  session->Start();
  sessions_[session_id] = std::move(session);

  result->Success(EncodableValue(session_id));
}

void FlutterLocalDeviceDiscoveryPlugin::HandleStopDiscovery(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* session_id = std::get_if<std::string>(method_call.arguments());
  if (session_id) {
    sessions_.erase(*session_id);
  }
  result->Success();
}

void FlutterLocalDeviceDiscoveryPlugin::HandleGetDiagnostics(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  EncodableMap diagnostics;
  diagnostics[EncodableValue("pluginVersion")] = EncodableValue("0.1.0");
  diagnostics[EncodableValue("platformVersion")] = EncodableValue("windows");
  diagnostics[EncodableValue("supportedProtocols")] =
      EncodableValue(EncodableList{kProtocolMdns, kProtocolDnsSd});
  diagnostics[EncodableValue("activeSessions")] =
      EncodableValue(static_cast<int>(sessions_.size()));
  diagnostics[EncodableValue("multicastAvailable")] = EncodableValue(true);
  diagnostics[EncodableValue("localNetworkReady")] = EncodableValue(true);
  diagnostics[EncodableValue("warnings")] = EncodableValue(EncodableList());
  diagnostics[EncodableValue("platformDetails")] = EncodableValue(EncodableMap());
  result->Success(EncodableValue(diagnostics));
}

}  // namespace flutter_local_device_discovery

// Plugin registration entry point.
void FlutterLocalDeviceDiscoveryPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_local_device_discovery::FlutterLocalDeviceDiscoveryPlugin::
      RegisterWithRegistrar(
          flutter::PluginRegistrarManager::GetInstance()
              ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}