import 'dart:async';
import 'package:dbus/dbus.dart';

class AvahiClient {
  DBusClient? _client;
  DBusRemoteObject? _server;

  Future<void> connect() async {
    _client = DBusClient.system();
    _server = DBusRemoteObject(_client!, name: 'org.freedesktop.Avahi', path: DBusObjectPath('/'));
  }

  Future<DBusRemoteObject> browseServices(String serviceType, String domain) async {
    final result = await _server!.callMethod('org.freedesktop.Avahi.Server', 'ServiceBrowserNew', [
      DBusInt32(-1),
      DBusInt32(-1),
      DBusString(serviceType),
      DBusString(domain),
      DBusUint32(0),
    ]);
    final path = result.returnValues[0] as DBusObjectPath;
    return DBusRemoteObject(_client!, name: 'org.freedesktop.Avahi', path: path);
  }

  Future<DBusRemoteObject> resolveService(
      int interfaceIndex, int protocol, String name, String type, String domain, int aprotocol) async {
    final result = await _server!.callMethod('org.freedesktop.Avahi.Server', 'ServiceResolverNew', [
      DBusInt32(interfaceIndex),
      DBusInt32(protocol),
      DBusString(name),
      DBusString(type),
      DBusString(domain),
      DBusInt32(aprotocol),
      DBusUint32(0),
    ]);
    final path = result.returnValues[0] as DBusObjectPath;
    return DBusRemoteObject(_client!, name: 'org.freedesktop.Avahi', path: path);
  }

  Future<DBusRemoteObject> registerService(String name, String type, String domain, String host, int port, List<String> txt) async {
    final result = await _server!.callMethod('org.freedesktop.Avahi.Server', 'EntryGroupNew', []);
    final path = result.returnValues[0] as DBusObjectPath;
    final group = DBusRemoteObject(_client!, name: 'org.freedesktop.Avahi', path: path);
    
    final txtBytes = txt.map((t) => DBusArray.byte(t.codeUnits)).toList();
    
    await group.callMethod('org.freedesktop.Avahi.EntryGroup', 'AddService', [
      DBusInt32(-1),
      DBusInt32(-1),
      DBusUint32(0),
      DBusString(name),
      DBusString(type),
      DBusString(domain),
      DBusString(host),
      DBusUint16(port),
      DBusArray(DBusSignature('ay'), txtBytes),
    ]);
    await group.callMethod('org.freedesktop.Avahi.EntryGroup', 'Commit', []);
    return group;
  }

  Future<String> getHostName() async {
    final result = await _server!.callMethod('org.freedesktop.Avahi.Server', 'GetHostName', []);
    return (result.returnValues[0] as DBusString).value;
  }

  void dispose() {
    _client?.close();
  }
}
