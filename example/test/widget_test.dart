import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_local_device_discovery_example/main.dart';

void main() {
  testWidgets('App renders with title', (WidgetTester tester) async {
    await tester.pumpWidget(const DeviceDiscoveryApp());

    expect(find.text('Local Discovery'), findsOneWidget);
    expect(find.text('v0.2 review console'), findsOneWidget);
    expect(find.text('mDNS / DNS-SD'), findsOneWidget);
    expect(find.text('SSDP'), findsAtLeastNWidgets(1));
    expect(find.text('UPnP metadata'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
