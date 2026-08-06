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

// The Windows implementation of flutter_local_device_discovery.
class FlutterLocalDeviceDiscoveryPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  FlutterLocalDeviceDiscoveryPlugin(
      flutter::PluginRegistrarWindows* registrar,
      std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel);

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

  flutter::PluginRegistrarWindows* registrar_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  std::unordered_map<std::string, std::unique_ptr<DiscoverySession>> sessions_;
};

}  // namespace flutter_local_device_discovery

#endif  // FLUTTER_PLUGIN_FLUTTER_LOCAL_DEVICE_DISCOVERY_PLUGIN_H_