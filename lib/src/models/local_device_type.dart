/// The type of a discovered device.
enum LocalDeviceType {
  /// The device type could not be determined.
  unknown,

  /// A general-purpose computer.
  computer,

  /// A mobile device (phone, tablet, etc.).
  mobileDevice,

  /// A tablet device.
  tablet,

  /// A network printer.
  printer,

  /// A network scanner.
  scanner,

  /// An IP camera.
  camera,

  /// A smart television.
  smartTv,

  /// A media renderer (DLNA, Chromecast, etc.).
  mediaRenderer,

  /// A media server (DLNA, Plex, etc.).
  mediaServer,

  /// A network speaker.
  speaker,

  /// A network router.
  router,

  /// A network gateway.
  gateway,

  /// A wireless access point.
  accessPoint,

  /// A network-attached storage device.
  nas,

  /// A storage device.
  storage,

  /// A server.
  server,

  /// A web server.
  webServer,

  /// A development server.
  developmentServer,

  /// A smart home hub.
  smartHomeHub,

  /// A home automation bridge.
  homeAutomationBridge,

  /// A sensor device.
  sensor,

  /// An actuator device.
  actuator,

  /// A point-of-sale terminal.
  posTerminal,

  /// A barcode scanner.
  barcodeScanner,

  /// A weighing scale.
  weighingScale,

  /// A medical device.
  medicalDevice,

  /// An industrial device.
  industrialDevice,

  /// A Raspberry Pi device.
  raspberryPi,

  /// A microcontroller.
  microcontroller,

  /// A custom device type.
  custom,
}