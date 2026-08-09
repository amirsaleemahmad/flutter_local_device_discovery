import '../models/metadata_security_policy.dart';
import '../models/upnp_device_description.dart';
import 'upnp_description_parser.dart';

/// Fetches and securely parses UPnP descriptions on supported native targets.
class UpnpDescriptionFetcher {
  const UpnpDescriptionFetcher({this.parser = const UpnpDescriptionParser()});

  final UpnpDescriptionParser parser;

  Future<UpnpDeviceDescription> fetch(
    Uri uri, {
    MetadataSecurityPolicy policy = MetadataSecurityPolicy.defaultPolicy,
  }) {
    throw UnsupportedError(
      'UPnP metadata fetching is unavailable on this platform',
    );
  }
}
