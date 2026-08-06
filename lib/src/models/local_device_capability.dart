/// A capability that a discovered device may support.
enum LocalDeviceCapability {
  /// HTTP server.
  http,

  /// HTTPS server.
  https,

  /// SSH server.
  ssh,

  /// FTP server.
  ftp,

  /// SFTP server.
  sftp,

  /// SMB file sharing.
  smb,

  /// Printing.
  printing,

  /// Secure printing (IPPS).
  securePrinting,

  /// Scanning.
  scanning,

  /// AirPlay.
  airPlay,

  /// Audio streaming.
  audioStreaming,

  /// Video streaming.
  videoStreaming,

  /// DLNA.
  dlna,

  /// UPnP.
  upnp,

  /// ONVIF.
  onvif,

  /// Google Cast.
  cast,

  /// MQTT.
  mqtt,

  /// WebSocket.
  websocket,

  /// File sharing.
  fileSharing,

  /// Remote desktop.
  remoteDesktop,

  /// Smart home.
  smartHome,

  /// Custom service.
  customService,
}