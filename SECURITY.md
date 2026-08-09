# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.2.x   | ✅                 |
| 0.1.x   | Security fixes only |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in `flutter_local_device_discovery`, please report it responsibly.

**Do NOT file a public GitHub issue for security vulnerabilities.**

Instead, please report security issues privately by emailing the maintainer at:

**amirsaleemahmad@gmail.com**

Please include the following information in your report:

- A description of the vulnerability
- The affected version(s)
- Steps to reproduce the issue
- Any potential impact
- Suggested fixes (if any)

You should receive a response within 48 hours. If you do not receive a response, please follow up.

## Security Considerations for This Package

This package discovers and describes devices on the local network. It is **not** a security scanner, penetration-testing framework, or exploitation tool.

### What This Package Does

- Discovers devices and services using standard protocols (mDNS, DNS-SD, Bonjour, SSDP, and UPnP)
- Resolves service addresses and ports
- Parses TXT records and device metadata
- Classifies devices based on observable information

### What This Package Does NOT Do

- Does not attempt default passwords or credentials
- Does not exploit services
- Does not perform vulnerability scans
- Does not open administrative pages automatically
- Does not execute UPnP actions automatically
- Does not send control commands without an explicit application action
- Does not perform aggressive port scanning
- Does not scan internet ranges

### Security Design Principles

1. **All local-network data is treated as untrusted.** Malformed packets, XML, and metadata must never crash the plugin or cause unsafe behavior.

2. **Metadata fetching is bounded.** UPnP metadata fetches are time-limited, size-limited, redirect-limited, and cancellable.

3. **XML parsing is secure.** External entity resolution is disabled. XML entity expansion and excessive nesting are prevented.

4. **No SSRF.** Metadata is only fetched from local addresses by default. Internet URL redirection from local devices is blocked.

   Connections are pinned to a validated address. Public and loopback targets are blocked by default, including after redirects.

5. **No telemetry.** The package contains no analytics SDK, no telemetry, and no data uploads.

6. **Safe logging.** The package never logs raw packets, credentials, private keys, or personally identifying data by default.

## Reporting Guidelines

When reporting a vulnerability, please:

1. **Do not** include exploit code in public channels
2. **Do not** include credentials or sensitive data
3. **Do** provide clear reproduction steps
4. **Do** suggest a severity level (Critical, High, Medium, Low)

## Disclosure Policy

We follow responsible disclosure:

1. Reporter submits vulnerability privately
2. Maintainer acknowledges within 48 hours
3. Maintainer works on a fix
4. Fix is released in a new version
5. Vulnerability is publicly disclosed after the fix is available

## Security-Related Configuration

### iOS Local Network Privacy

Applications using this package must declare `NSLocalNetworkUsageDescription` and `NSBonjourServices` in their `Info.plist`. Only declare service types your application actually uses.

### Android Permissions

Applications using this package need the following permissions:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
```

## Acknowledgments

We appreciate the community's help in keeping this package secure. Thank you for responsible disclosure.
