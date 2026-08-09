import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../models/metadata_security_policy.dart';
import '../models/upnp_device_description.dart';
import 'upnp_description_parser.dart';

/// Fetches UPnP descriptions with redirect, size, timeout, and SSRF limits.
class UpnpDescriptionFetcher {
  const UpnpDescriptionFetcher({this.parser = const UpnpDescriptionParser()});

  final UpnpDescriptionParser parser;

  Future<UpnpDeviceDescription> fetch(
    Uri uri, {
    MetadataSecurityPolicy policy = MetadataSecurityPolicy.defaultPolicy,
  }) async {
    final client = HttpClient()
      ..autoUncompress = true
      ..connectionTimeout = policy.timeoutDuration
      ..idleTimeout = policy.timeoutDuration
      ..maxConnectionsPerHost = 2
      ..findProxy = (_) => 'DIRECT';

    client.connectionFactory = (url, proxyHost, proxyPort) async {
      if (proxyHost != null || proxyPort != null) {
        throw const HttpException('Proxies are disabled for UPnP metadata');
      }
      final address = await _validatedAddress(url, policy);
      final port = url.hasPort
          ? url.port
          : url.scheme.toLowerCase() == 'https'
              ? 443
              : 80;
      if (url.scheme.toLowerCase() == 'https') {
        final rawTask = await Socket.startConnect(address, port);
        final secureSocket = rawTask.socket.then<Socket>(
          (socket) => SecureSocket.secure(socket, host: url.host),
        );
        return ConnectionTask.fromSocket<Socket>(secureSocket, rawTask.cancel);
      }
      return Socket.startConnect(address, port);
    };

    try {
      return await _fetch(client, uri, policy).timeout(policy.timeoutDuration);
    } finally {
      client.close(force: true);
    }
  }

  Future<UpnpDeviceDescription> _fetch(
    HttpClient client,
    Uri initialUri,
    MetadataSecurityPolicy policy,
  ) async {
    var currentUri = initialUri;
    for (var redirectCount = 0;
        redirectCount <= policy.maxRedirects;
        redirectCount++) {
      await _validatedAddress(currentUri, policy);
      final request = await client.getUrl(currentUri);
      request
        ..followRedirects = false
        ..maxRedirects = 0
        ..headers.set(HttpHeaders.acceptHeader, 'text/xml, application/xml')
        ..headers.set(
          HttpHeaders.userAgentHeader,
          'flutter_local_device_discovery/0.2.0',
        );
      final response = await request.close();

      if (_isRedirect(response.statusCode)) {
        final location = response.headers.value(HttpHeaders.locationHeader);
        await response.drain<void>();
        if (location == null || location.trim().isEmpty) {
          throw const HttpException('UPnP redirect has no Location header');
        }
        if (redirectCount >= policy.maxRedirects) {
          throw HttpException(
            'UPnP redirect limit (${policy.maxRedirects}) exceeded',
            uri: currentUri,
          );
        }
        currentUri = currentUri.resolve(location.trim());
        continue;
      }

      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw HttpException(
          'UPnP description returned HTTP ${response.statusCode}',
          uri: currentUri,
        );
      }

      final contentLength = response.contentLength;
      if (contentLength > policy.maxResponseSizeBytes) {
        await response.drain<void>();
        throw HttpException(
          'UPnP description exceeds ${policy.maxResponseSizeBytes} bytes',
          uri: currentUri,
        );
      }

      final builder = BytesBuilder(copy: false);
      var received = 0;
      await for (final chunk in response) {
        received += chunk.length;
        if (received > policy.maxResponseSizeBytes) {
          throw HttpException(
            'UPnP description exceeds ${policy.maxResponseSizeBytes} bytes',
            uri: currentUri,
          );
        }
        builder.add(chunk);
      }

      final body = _decodeBody(
        builder.takeBytes(),
        response.headers.contentType?.charset,
      );
      return parser.parse(body, documentUri: currentUri, policy: policy);
    }
    throw StateError('Unreachable redirect state');
  }

  Future<InternetAddress> _validatedAddress(
    Uri uri,
    MetadataSecurityPolicy policy,
  ) async {
    final scheme = uri.scheme.toLowerCase();
    if ((scheme != 'http' && scheme != 'https') || uri.host.isEmpty) {
      throw FormatException('Unsupported UPnP description URL: $uri');
    }
    if (uri.userInfo.isNotEmpty) {
      throw const FormatException(
        'UPnP description URLs cannot contain user info',
      );
    }

    final literal = InternetAddress.tryParse(uri.host);
    final addresses = literal == null
        ? await InternetAddress.lookup(uri.host).timeout(policy.timeoutDuration)
        : <InternetAddress>[literal];
    if (addresses.isEmpty) {
      throw SocketException('Could not resolve ${uri.host}');
    }

    if (policy.allowExternalAddresses) return addresses.first;
    for (final address in addresses) {
      if (_isLocalAddress(address, policy)) return address;
    }
    throw HttpException(
      'Blocked non-local UPnP metadata address for ${uri.host}',
      uri: uri,
    );
  }

  bool _isLocalAddress(InternetAddress address, MetadataSecurityPolicy policy) {
    if (address.isLoopback) return policy.allowLoopbackAddresses;
    if (address.isLinkLocal) return true;
    final bytes = address.rawAddress;
    if (address.type == InternetAddressType.IPv4 && bytes.length == 4) {
      return bytes[0] == 10 ||
          (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31) ||
          (bytes[0] == 192 && bytes[1] == 168);
    }
    if (address.type == InternetAddressType.IPv6 && bytes.length == 16) {
      return (bytes[0] & 0xfe) == 0xfc;
    }
    return false;
  }

  bool _isRedirect(int statusCode) =>
      statusCode == HttpStatus.movedPermanently ||
      statusCode == HttpStatus.found ||
      statusCode == HttpStatus.seeOther ||
      statusCode == HttpStatus.temporaryRedirect ||
      statusCode == HttpStatus.permanentRedirect;

  String _decodeBody(Uint8List bytes, String? charset) {
    final normalized = charset?.toLowerCase();
    if (normalized == 'iso-8859-1' || normalized == 'latin1') {
      return latin1.decode(bytes);
    }
    return utf8.decode(bytes, allowMalformed: true);
  }
}
