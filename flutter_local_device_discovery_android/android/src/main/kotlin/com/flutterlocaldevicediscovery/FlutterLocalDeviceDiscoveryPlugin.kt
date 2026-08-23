package com.flutterlocaldevicediscovery

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.net.Inet4Address
import java.net.Inet6Address
import java.net.InetAddress
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger

/** FlutterLocalDeviceDiscoveryPlugin */
class FlutterLocalDeviceDiscoveryPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var applicationContext: Context
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var nsdManager: NsdManager
    private lateinit var wifiManager: WifiManager
    private lateinit var connectivityManager: ConnectivityManager

    private val sessions = ConcurrentHashMap<String, DiscoverySession>()
    private val registrations = ConcurrentHashMap<String, NsdManager.RegistrationListener>()
    private val multicastLockRefCount = AtomicInteger(0)
    private var multicastLock: WifiManager.MulticastLock? = null
    private var eventSink: EventChannel.EventSink? = null
    private val networkCallback = object : ConnectivityManager.NetworkCallback() {
      override fun onAvailable(network: Network) {
        emitNetworkChanged()
      }

      override fun onLost(network: Network) {
        emitNetworkChanged()
      }

      override fun onCapabilitiesChanged(network: Network, networkCapabilities: NetworkCapabilities) {
        emitNetworkChanged()
      }
    }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_local_device_discovery")
    channel.setMethodCallHandler(this)
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_local_device_discovery/events")
    eventChannel.setStreamHandler(this)

    nsdManager = applicationContext.getSystemService(Context.NSD_SERVICE) as NsdManager
    wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
    connectivityManager = applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    connectivityManager.registerDefaultNetworkCallback(networkCallback)
    
    nativeSsdpEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_local_device_discovery/native_ssdp_events")
    nativeSsdpEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
      override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        nativeSsdpEventSink = events
      }
      override fun onCancel(arguments: Any?) {
        nativeSsdpEventSink = null
      }
    })

    nativeWsDiscoveryEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_local_device_discovery/native_ws_discovery_events")
    nativeWsDiscoveryEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
      override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        nativeWsDiscoveryEventSink = events
      }
      override fun onCancel(arguments: Any?) {
        nativeWsDiscoveryEventSink = null
      }
    })
  }

  private var nativeSsdpEngine: NativeSsdpEngine? = null
  private var nativeSsdpEventSink: EventChannel.EventSink? = null
  private lateinit var nativeSsdpEventChannel: EventChannel

  private var nativeWsDiscoveryEngine: NativeWsDiscoveryEngine? = null
  private var nativeWsDiscoveryEventSink: EventChannel.EventSink? = null
  private lateinit var nativeWsDiscoveryEventChannel: EventChannel

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
    connectivityManager.unregisterNetworkCallback(networkCallback)
    stopAllSessions()
    releaseMulticastLock()
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getCapabilities" -> handleGetCapabilities(call, result)
      "checkReadiness" -> handleCheckReadiness(call, result)
      "startDiscovery" -> handleStartDiscovery(call, result)
      "pauseDiscovery" -> handlePauseDiscovery(call, result)
      "resumeDiscovery" -> handleResumeDiscovery(call, result)
      "stopDiscovery" -> handleStopDiscovery(call, result)
      "registerService" -> handleRegisterService(call, result)
      "updateRegisteredService" -> handleUpdateRegisteredService(call, result)
      "unregisterService" -> handleUnregisterService(call, result)
      "getDiagnostics" -> handleGetDiagnostics(call, result)
      "startNativeSsdp" -> handleStartNativeSsdp(call, result)
      "stopNativeSsdp" -> handleStopNativeSsdp(call, result)
      "startNativeWsDiscovery" -> handleStartNativeWsDiscovery(call, result)
      "stopNativeWsDiscovery" -> handleStopNativeWsDiscovery(call, result)
      "getNetworkInfo" -> handleGetNetworkInfo(call, result)
      "getGatewayInfo" -> handleGetGatewayInfo(call, result)
      else -> result.notImplemented()
    }
  }

  private fun handleGetCapabilities(call: MethodCall, result: Result) {
    val protocols = listOf(0, 1, 2) // mdns, dnsSd, bonjour
    result.success(
      mapOf(
        "supportedProtocols" to protocols,
        "supportsServiceRegistration" to true,
        "supportsIpv4" to true,
        "supportsIpv6" to true,
        "supportsMultipleInterfaces" to true,
        "supportsNetworkSpecificDiscovery" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O),
        "supportsNeighborTable" to false,
        "supportsReachability" to false,
        "supportsSafePortProbe" to false,
        "requiresLocalNetworkPermission" to false,
        "requiresMulticastPermission" to true,
        "platformDetails" to mapOf(
          "androidSdk" to Build.VERSION.SDK_INT,
          "nsdAvailable" to true,
        ),
      ),
    )
  }

  private fun handleCheckReadiness(call: MethodCall, result: Result) {
    val request = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
    val requirements = mutableListOf<String>()
    val warnings = mutableListOf<String>()

    val activeNetwork = connectivityManager.activeNetwork
    if (activeNetwork == null) {
      requirements.add("network_unavailable")
    }

    val capabilities = connectivityManager.getNetworkCapabilities(activeNetwork)
    if (capabilities != null && !capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) {
      warnings.add("network_may_not_support_internet")
    }

    result.success(
      mapOf(
        "canStart" to (requirements.isEmpty()),
        "requirements" to requirements,
        "warnings" to warnings,
        "platformDetails" to mapOf(
          "networkAvailable" to (activeNetwork != null),
        ),
      ),
    )
  }

  private fun handleStartDiscovery(call: MethodCall, result: Result) {
    val args = call.arguments as? Map<*, *> ?: emptyMap<Any?, Any?>()
    val sessionId = UUID.randomUUID().toString()
    val serviceTypes = (args["serviceTypes"] as? List<*>)?.filterIsInstance<String>() ?: emptyList()
    val resolveServices = (args["resolveServices"] as? Boolean) ?: true

    val session = DiscoverySession(
      sessionId = sessionId,
      serviceTypes = serviceTypes,
      resolveServices = resolveServices,
    )

    sessions[sessionId] = session
    acquireMulticastLock()

    try {
      session.start(nsdManager) { event -> emitEvent(event) }
      result.success(sessionId)
    } catch (e: Exception) {
      sessions.remove(sessionId)
      releaseMulticastLock()
      result.error("discovery_start_failed", e.message, null)
    }
  }

  private fun handlePauseDiscovery(call: MethodCall, result: Result) {
    val sessionId = call.arguments as? String
    val session = sessionId?.let { sessions[it] }
    if (session == null) {
      result.error("session_not_found", "No session found for $sessionId", null)
      return
    }
    session.pause()
    result.success(null)
  }

  private fun handleResumeDiscovery(call: MethodCall, result: Result) {
    val sessionId = call.arguments as? String
    val session = sessionId?.let { sessions[it] }
    if (session == null) {
      result.error("session_not_found", "No session found for $sessionId", null)
      return
    }
    session.resume()
    result.success(null)
  }

  private fun handleStopDiscovery(call: MethodCall, result: Result) {
    val sessionId = call.arguments as? String
    val session = sessionId?.let { sessions.remove(it) }
    if (session != null) {
      session.stop()
      releaseMulticastLock()
    }
    result.success(null)
  }

  private fun handleRegisterService(call: MethodCall, result: Result) {
    val args = call.arguments as? Map<*, *> ?: emptyMap<Any?, Any?>()
    val instanceName = args["instanceName"] as? String ?: ""
    val serviceType = args["serviceType"] as? String ?: ""
    val port = (args["port"] as? Number)?.toInt() ?: 0
    val rawTxt = args["txtRecords"] as? Map<*, *> ?: emptyMap<Any?, Any?>()

    if (instanceName.isEmpty() || serviceType.isEmpty() || port <= 0) {
      result.error("invalid_configuration", "instanceName, serviceType, and port are required", null)
      return
    }

    val registrationId = UUID.randomUUID().toString()
    val serviceInfo = NsdServiceInfo().apply {
      this.serviceName = instanceName
      this.serviceType = serviceType
      this.port = port
      rawTxt.forEach { (key, value) ->
        if (key is String && value is ByteArray) {
          setAttribute(key, String(value, Charsets.UTF_8))
        }
      }
    }

    val listener = object : NsdManager.RegistrationListener {
      override fun onServiceRegistered(serviceInfo: NsdServiceInfo) {
        result.success(
          mapOf(
            "registrationId" to registrationId,
            "assignedName" to serviceInfo.serviceName,
            "serviceType" to serviceInfo.serviceType,
            "port" to serviceInfo.port,
          ),
        )
      }

      override fun onRegistrationFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
        registrations.remove(registrationId)
        result.error("service_registration_failed", "Registration failed with code $errorCode", null)
      }

      override fun onServiceUnregistered(serviceInfo: NsdServiceInfo) {
        registrations.remove(registrationId)
      }

      override fun onUnregistrationFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
        registrations.remove(registrationId)
      }
    }

    registrations[registrationId] = listener
    nsdManager.registerService(serviceInfo, NsdManager.PROTOCOL_DNS_SD, listener)
  }

  private fun handleUpdateRegisteredService(call: MethodCall, result: Result) {
    result.notImplemented()
  }

  private fun handleUnregisterService(call: MethodCall, result: Result) {
    val registrationId = call.arguments as? String
    val listener = registrationId?.let { registrations.remove(it) }
    if (listener != null) {
      nsdManager.unregisterService(listener)
    }
    result.success(null)
  }

  private fun handleGetDiagnostics(call: MethodCall, result: Result) {
    result.success(
      mapOf(
        "pluginVersion" to "0.2.0",
        "platformVersion" to Build.VERSION.RELEASE,
        "supportedProtocols" to listOf(0, 1, 2),
        "activeSessions" to sessions.size,
        "multicastAvailable" to true,
        "localNetworkReady" to (connectivityManager.activeNetwork != null),
        "rawObservationCount" to sessions.values.sumOf { it.seenServicesCount },
        "deduplicatedDeviceCount" to sessions.values.sumOf { it.deviceCount },
        "resolutionSuccessCount" to sessions.values.sumOf { it.resolutionSuccessCount },
        "resolutionFailureCount" to sessions.values.sumOf { it.resolutionFailureCount },
        "warnings" to emptyList<String>(),
        "platformDetails" to mapOf(
          "androidSdk" to Build.VERSION.SDK_INT,
        ),
      ),
      ),
    )
  }

  private fun handleStartNativeSsdp(call: MethodCall, result: Result) {
    val args = call.arguments as? Map<*, *> ?: emptyMap<Any?, Any?>()
    val sessionId = UUID.randomUUID().toString()
    val searchTargets = (args["searchTargets"] as? List<*>)?.filterIsInstance<String>() ?: emptyList()
    
    acquireMulticastLock()
    nativeSsdpEngine = NativeSsdpEngine(sessionId, searchTargets) { event ->
      Handler(Looper.getMainLooper()).post {
        nativeSsdpEventSink?.success(event)
      }
    }
    nativeSsdpEngine?.start()
    result.success(sessionId)
  }

  private fun handleStopNativeSsdp(call: MethodCall, result: Result) {
    nativeSsdpEngine?.stop()
    nativeSsdpEngine = null
    releaseMulticastLock()
    result.success(null)
  }

  private fun handleStartNativeWsDiscovery(call: MethodCall, result: Result) {
    val sessionId = UUID.randomUUID().toString()
    
    acquireMulticastLock()
    nativeWsDiscoveryEngine = NativeWsDiscoveryEngine(sessionId) { event ->
      Handler(Looper.getMainLooper()).post {
        nativeWsDiscoveryEventSink?.success(event)
      }
    }
    nativeWsDiscoveryEngine?.start()
    result.success(sessionId)
  }

  private fun handleStopNativeWsDiscovery(call: MethodCall, result: Result) {
    nativeWsDiscoveryEngine?.stop()
    nativeWsDiscoveryEngine = null
    releaseMulticastLock()
    result.success(null)
  }

  private fun handleGetNetworkInfo(call: MethodCall, result: Result) {
    val wifiInfo = wifiManager.connectionInfo
    val linkProps = connectivityManager.getLinkProperties(connectivityManager.activeNetwork)
    
    result.success(mapOf(
      "ssid" to wifiInfo.ssid,
      "bssid" to wifiInfo.bssid,
      "rssi" to wifiInfo.rssi,
      "linkSpeed" to wifiInfo.linkSpeed,
      "frequency" to wifiInfo.frequency,
      "gateway" to linkProps?.routes?.find { it.isDefaultRoute }?.gateway?.hostAddress
    ))
  }

  private fun handleGetGatewayInfo(call: MethodCall, result: Result) {
    val dhcpInfo = wifiManager.dhcpInfo
    result.success(mapOf(
      "gateway" to android.text.format.Formatter.formatIpAddress(dhcpInfo.gateway)
    ))
  }

  private fun acquireMulticastLock() {
    if (multicastLockRefCount.incrementAndGet() == 1) {
      multicastLock = wifiManager.createMulticastLock("flutter_local_device_discovery")
      multicastLock?.setReferenceCounted(false)
      multicastLock?.acquire()
    }
  }

  private fun releaseMulticastLock() {
    if (multicastLockRefCount.decrementAndGet() <= 0) {
      multicastLockRefCount.set(0)
      multicastLock?.let {
        if (it.isHeld) {
          it.release()
        }
      }
      multicastLock = null
    }
  }

  private fun stopAllSessions() {
    sessions.values.forEach { session -> session.stop() }
    sessions.clear()
    multicastLockRefCount.set(0)
    multicastLock?.let {
      if (it.isHeld) it.release()
    }
    multicastLock = null
  }

  private fun emitNetworkChanged() {
    emitEvent(
      mapOf(
        "type" to 7, // LocalNetworkChanged
        "timestamp" to isoTimestamp(),
      ),
    )
  }

  private fun emitEvent(event: Map<String, Any?>) {
    Handler(Looper.getMainLooper()).post {
      eventSink?.success(event)
    }
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

}

private val isoFormatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
  timeZone = TimeZone.getTimeZone("UTC")
}

private fun isoTimestamp(): String = synchronized(isoFormatter) {
  isoFormatter.format(Date())
}

/** A single discovery session using Android NSD. */
class DiscoverySession(
  private val sessionId: String,
  private val serviceTypes: List<String>,
  private val resolveServices: Boolean,
) {
  private val discoveryListeners = mutableListOf<NsdManager.DiscoveryListener>()
  private val seenServices = ConcurrentHashMap<String, Long>()
  private var nsdManager: NsdManager? = null
  private var paused = false
  private var stopped = false

  var deviceCount: Int = 0
    private set
  var resolutionSuccessCount: Int = 0
    private set
  var resolutionFailureCount: Int = 0
    private set
  val seenServicesCount: Int
    get() = seenServices.size

  fun start(nsdManager: NsdManager, emit: (Map<String, Any?>) -> Unit) {
    this.nsdManager = nsdManager
    serviceTypes.forEach { rawServiceType ->
      // Android NSD requires the service type with a trailing dot,
      // e.g. "_airplay._tcp." instead of "_airplay._tcp"
      val serviceType = if (rawServiceType.endsWith(".")) rawServiceType else "$rawServiceType."
      val listener = createDiscoveryListener(nsdManager, serviceType, emit)
      discoveryListeners.add(listener)
      nsdManager.discoverServices(serviceType, NsdManager.PROTOCOL_DNS_SD, listener)
    }
  }

  fun pause() {
    paused = true
  }

  fun resume() {
    paused = false
  }

  fun stop() {
    if (stopped) return
    stopped = true
    val manager = nsdManager
    if (manager != null) {
      discoveryListeners.forEach { listener ->
        try {
          manager.stopServiceDiscovery(listener)
        } catch (_: IllegalArgumentException) {
          // The listener may already have stopped after a platform failure.
        } catch (_: IllegalStateException) {
          // NSD can reject shutdown while the adapter is being torn down.
        }
      }
    }
    discoveryListeners.clear()
    nsdManager = null
  }

  private fun createDiscoveryListener(
    nsdManager: NsdManager,
    serviceType: String,
    emit: (Map<String, Any?>) -> Unit,
  ): NsdManager.DiscoveryListener {
    return object : NsdManager.DiscoveryListener {
      override fun onDiscoveryStarted(serviceType: String) {
        emit(
          mapOf(
            "type" to 0, // LocalDiscoveryStarted
            "sessionId" to sessionId,
            "protocol" to 0,
            "timestamp" to isoTimestamp(),
          ),
        )
      }

      override fun onServiceFound(serviceInfo: NsdServiceInfo) {
        if (paused || stopped) return
        val now = isoTimestamp()
        val nowMs = System.currentTimeMillis()
        val lastSeen = seenServices[serviceInfo.serviceName]
        if (lastSeen != null && nowMs - lastSeen < 1000) {
          return // deduplicate rapid re-announcements
        }
        seenServices[serviceInfo.serviceName] = nowMs

        val serviceMap = mapOf(
          "id" to "${sessionId}:${serviceInfo.serviceName}:${serviceInfo.serviceType}",
          "instanceName" to serviceInfo.serviceName,
          "serviceType" to serviceInfo.serviceType,
          "domain" to "local.",
          "transport" to 0, // TCP
          "protocols" to listOf(0, 1),
          "firstSeenAt" to now,
          "lastSeenAt" to now,
        )

        emit(
          mapOf(
            "type" to 4, // LocalServiceAdded
            "sessionId" to sessionId,
            "protocol" to 0,
            "service" to serviceMap,
            "timestamp" to now,
          ),
        )

        // Also emit a device added event.
        deviceCount++
        val deviceMap = mapOf(
          "id" to "${sessionId}:${serviceInfo.serviceName}",
          "displayName" to serviceInfo.serviceName,
          "hostname" to serviceInfo.serviceName,
          "type" to 0, // unknown
          "protocols" to listOf(0, 1),
          "services" to listOf(serviceMap),
          "firstSeenAt" to now,
          "lastSeenAt" to now,
        )

        emit(
          mapOf(
            "type" to 1, // LocalDeviceAdded
            "sessionId" to sessionId,
            "protocol" to 0,
            "device" to deviceMap,
            "timestamp" to now,
          ),
        )

        if (resolveServices) {
          resolveService(nsdManager, serviceInfo, emit)
        }
      }

      override fun onServiceLost(serviceInfo: NsdServiceInfo) {
        if (stopped) return
        val now = isoTimestamp()
        emit(
          mapOf(
            "type" to 6, // LocalServiceRemoved
            "sessionId" to sessionId,
            "protocol" to 0,
            "service" to mapOf(
              "id" to "${sessionId}:${serviceInfo.serviceName}:${serviceInfo.serviceType}",
              "instanceName" to serviceInfo.serviceName,
              "serviceType" to serviceInfo.serviceType,
              "domain" to "local.",
              "transport" to 0,
              "protocols" to listOf(0, 1),
            ),
            "timestamp" to now,
          ),
        )

        // Also emit a device removed event.
        emit(
          mapOf(
            "type" to 3, // LocalDeviceRemoved
            "sessionId" to sessionId,
            "protocol" to 0,
            "device" to mapOf(
              "id" to "${sessionId}:${serviceInfo.serviceName}",
              "displayName" to serviceInfo.serviceName,
              "hostname" to serviceInfo.serviceName,
              "type" to 0,
              "protocols" to listOf(0, 1),
            ),
            "timestamp" to now,
          ),
        )
      }

      override fun onDiscoveryStopped(serviceType: String) {
        emit(
          mapOf(
            "type" to 10, // LocalDiscoveryStopped
            "sessionId" to sessionId,
            "protocol" to 0,
            "timestamp" to isoTimestamp(),
          ),
        )
      }

      override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
        emit(
          mapOf(
            "type" to 9, // LocalDiscoveryFailure
            "sessionId" to sessionId,
            "protocol" to 0,
            "errorCode" to "discovery_start_failed",
            "errorMessage" to "Failed to start discovery for $serviceType (code $errorCode)",
            "timestamp" to isoTimestamp(),
          ),
        )
      }

      override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {
        emit(
          mapOf(
            "type" to 9,
            "sessionId" to sessionId,
            "protocol" to 0,
            "errorCode" to "discovery_stop_failed",
            "errorMessage" to "Failed to stop discovery for $serviceType (code $errorCode)",
            "timestamp" to isoTimestamp(),
          ),
        )
      }
    }
  }

  private fun resolveService(
    nsdManager: NsdManager,
    serviceInfo: NsdServiceInfo,
    emit: (Map<String, Any?>) -> Unit,
  ) {
    val resolveListener = object : NsdManager.ResolveListener {
      override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
        resolutionFailureCount++
        emit(
          mapOf(
            "type" to 9,
            "sessionId" to sessionId,
            "protocol" to 0,
            "errorCode" to "service_resolution_failed",
            "errorMessage" to "Failed to resolve ${serviceInfo.serviceName} (code $errorCode)",
            "timestamp" to isoTimestamp(),
          ),
        )
      }

      override fun onServiceResolved(resolvedInfo: NsdServiceInfo) {
        resolutionSuccessCount++
        val now = isoTimestamp()
        val addresses = mutableListOf<Map<String, Any?>>()
        resolvedInfo.host?.let { host ->
          addresses.add(
            mapOf(
              "address" to host.hostAddress,
              "family" to if (host is Inet4Address) 4 else if (host is Inet6Address) 6 else 0,
              "isLoopback" to host.isLoopbackAddress,
              "isLinkLocal" to host.isLinkLocalAddress,
              "isPrivate" to host.isSiteLocalAddress,
              "isMulticast" to host.isMulticastAddress,
            ),
          )
        }

        val txtRecords = mutableMapOf<String, ByteArray>()
        val textTxtRecords = mutableMapOf<String, String>()
        resolvedInfo.attributes?.forEach { (key, value) ->
          val bytes = value
          txtRecords[key] = bytes
          textTxtRecords[key] = String(bytes, Charsets.UTF_8)
        }

        val serviceMap = mapOf(
          "id" to "${sessionId}:${resolvedInfo.serviceName}:${resolvedInfo.serviceType}",
          "instanceName" to resolvedInfo.serviceName,
          "serviceType" to resolvedInfo.serviceType,
          "domain" to "local.",
          "hostname" to resolvedInfo.host?.hostName,
          "addresses" to addresses,
          "port" to resolvedInfo.port,
          "transport" to 0,
          "rawTxtRecords" to txtRecords,
          "textTxtRecords" to textTxtRecords,
          "protocols" to listOf(0, 1),
          "resolved" to true,
          "lastSeenAt" to now,
        )

        emit(
          mapOf(
            "type" to 5, // LocalServiceUpdated
            "sessionId" to sessionId,
            "protocol" to 0,
            "service" to serviceMap,
            "timestamp" to now,
          ),
        )

        // Also emit a device updated event with resolved address.
        emit(
          mapOf(
            "type" to 2, // LocalDeviceUpdated
            "sessionId" to sessionId,
            "protocol" to 0,
            "device" to mapOf(
              "id" to "${sessionId}:${resolvedInfo.serviceName}",
              "displayName" to resolvedInfo.serviceName,
              "hostname" to resolvedInfo.host?.hostName,
              "type" to 0,
              "addresses" to addresses,
              "protocols" to listOf(0, 1),
              "lastSeenAt" to now,
            ),
            "timestamp" to now,
          ),
        )
      }
    }

    nsdManager.resolveService(serviceInfo, resolveListener)
  }
}

class NativeSsdpEngine(
    private val sessionId: String,
    private val searchTargets: List<String>,
    private val eventCallback: (Map<String, Any?>) -> Unit
) {
    private var thread: Thread? = null
    private var socket: java.net.MulticastSocket? = null
    private var isRunning = false

    fun start() {
        if (isRunning) return
        isRunning = true
        thread = Thread {
            try {
                socket = java.net.MulticastSocket(1900)
                socket?.joinGroup(java.net.InetAddress.getByName("239.255.255.250"))
                val buffer = ByteArray(8192)
                
                eventCallback(mapOf(
                    "type" to 0,
                    "sessionId" to sessionId,
                    "protocol" to 1,
                    "timestamp" to isoTimestamp()
                ))

                while (isRunning) {
                    val packet = java.net.DatagramPacket(buffer, buffer.size)
                    socket?.receive(packet)
                    
                    val data = String(packet.data, 0, packet.length)
                    // Parse SSDP and send event
                    val address = packet.address.hostAddress
                    eventCallback(mapOf(
                        "type" to 4,
                        "sessionId" to sessionId,
                        "protocol" to 1,
                        "service" to mapOf(
                            "id" to "$sessionId:$address",
                            "address" to address,
                            "raw" to data
                        ),
                        "timestamp" to isoTimestamp()
                    ))
                }
            } catch (e: Exception) {
                // Handle error
            }
        }
        thread?.start()
    }

    fun stop() {
        isRunning = false
        try {
            socket?.leaveGroup(java.net.InetAddress.getByName("239.255.255.250"))
            socket?.close()
        } catch (e: Exception) {
        }
        socket = null
        thread?.interrupt()
        thread = null
        
        eventCallback(mapOf(
            "type" to 10,
            "sessionId" to sessionId,
            "protocol" to 1,
            "timestamp" to isoTimestamp()
        ))
    }
}

class NativeWsDiscoveryEngine(
    private val sessionId: String,
    private val eventCallback: (Map<String, Any?>) -> Unit
) {
    private var thread: Thread? = null
    private var socket: java.net.MulticastSocket? = null
    private var isRunning = false

    fun start() {
        if (isRunning) return
        isRunning = true
        thread = Thread {
            try {
                socket = java.net.MulticastSocket(3702)
                val group = java.net.InetAddress.getByName("239.255.255.250")
                socket?.joinGroup(group)
                val buffer = ByteArray(8192)
                
                eventCallback(mapOf(
                    "type" to 0,
                    "sessionId" to sessionId,
                    "protocol" to 2, // WS-Discovery Protocol ID
                    "timestamp" to isoTimestamp()
                ))

                // Send Probe
                val uuid = java.util.UUID.randomUUID().toString()
                val probeXml = """
                    <?xml version="1.0" encoding="utf-8"?>
                    <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsd="http://schemas.xmlsoap.org/ws/2005/04/discovery">
                      <soap:Header>
                        <wsa:To>urn:schemas-xmlsoap-org:ws:2005:04:discovery</wsa:To>
                        <wsa:Action>http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</wsa:Action>
                        <wsa:MessageID>urn:uuid:\$uuid</wsa:MessageID>
                      </soap:Header>
                      <soap:Body>
                        <wsd:Probe/>
                      </soap:Body>
                    </soap:Envelope>
                """.trimIndent()
                val probeBytes = probeXml.toByteArray(Charsets.UTF_8)
                val sendPacket = java.net.DatagramPacket(probeBytes, probeBytes.size, group, 3702)
                socket?.send(sendPacket)

                while (isRunning) {
                    val packet = java.net.DatagramPacket(buffer, buffer.size)
                    socket?.receive(packet)
                    
                    val data = String(packet.data, 0, packet.length)
                    // Parse WS-Discovery and send event
                    val address = packet.address.hostAddress
                    
                    // Simple parsing for EndpointReference, Types, Scopes, XAddrs
                    val endpointReference = Regex("<wsa:Address>(.*?)</wsa:Address>").find(data)?.groupValues?.get(1)
                    val types = Regex("<wsd:Types>(.*?)</wsd:Types>").find(data)?.groupValues?.get(1)
                    val scopes = Regex("<wsd:Scopes>(.*?)</wsd:Scopes>").find(data)?.groupValues?.get(1)
                    val xAddrs = Regex("<wsd:XAddrs>(.*?)</wsd:XAddrs>").find(data)?.groupValues?.get(1)
                    
                    if (endpointReference != null) {
                        eventCallback(mapOf(
                            "type" to 4,
                            "sessionId" to sessionId,
                            "protocol" to 2,
                            "service" to mapOf(
                                "id" to "\$sessionId:\$address",
                                "address" to address,
                                "endpointReference" to endpointReference,
                                "types" to types,
                                "scopes" to scopes,
                                "xAddrs" to xAddrs,
                                "raw" to data
                            ),
                            "timestamp" to isoTimestamp()
                        ))
                    }
                }
            } catch (e: Exception) {
                // Handle error
            }
        }
        thread?.start()
    }

    fun stop() {
        isRunning = false
        try {
            socket?.leaveGroup(java.net.InetAddress.getByName("239.255.255.250"))
            socket?.close()
        } catch (e: Exception) {
        }
        socket = null
        thread?.interrupt()
        thread = null
        
        eventCallback(mapOf(
            "type" to 10,
            "sessionId" to sessionId,
            "protocol" to 2,
            "timestamp" to isoTimestamp()
        ))
    }
}
