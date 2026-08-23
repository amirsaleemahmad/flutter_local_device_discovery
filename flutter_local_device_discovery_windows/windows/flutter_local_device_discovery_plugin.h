#ifndef FLUTTER_PLUGIN_FLUTTER_LOCAL_DEVICE_DISCOVERY_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_LOCAL_DEVICE_DISCOVERY_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>
#include <unordered_map>

namespace flutter_local_device_discovery {

// Forward declarations
class DiscoverySession;
class DiscoveryEventStreamHandler;
class RegisteredService;

// The Windows implementation of flutter_local_device_discovery.
class FlutterLocalDeviceDiscoveryPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  FlutterLocalDeviceDiscoveryPlugin(
      flutter::PluginRegistrarWindows* registrar,
      std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel,
      DiscoveryEventStreamHandler* stream_handler);

  virtual ~FlutterLocalDeviceDiscoveryPlugin();

 private:
  // Called when a method is called on this plugin.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void HandleGetCapabilities(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleCheckReadiness(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleStartDiscovery(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleStopDiscovery(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleGetDiagnostics(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleRegisterService(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleUpdateRegisteredService(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleStartNativeSsdp(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleStopNativeSsdp(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleStartNativeWsDiscovery(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleStopNativeWsDiscovery(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleGetNetworkInfo(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleGetGatewayInfo(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void HandleUnregisterService(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  flutter::PluginRegistrarWindows* registrar_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  DiscoveryEventStreamHandler* stream_handler_;
  void* ws_discovery_engine_{nullptr};
  std::unordered_map<std::string, std::unique_ptr<DiscoverySession>> sessions_;
  std::unordered_map<std::string, std::unique_ptr<RegisteredService>> registered_services_;
};

}  // namespace flutter_local_device_discovery

#endif  // FLUTTER_PLUGIN_FLUTTER_LOCAL_DEVICE_DISCOVERY_PLUGIN_H_