import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_local_device_discovery_example/main.dart';

void main() {
  testWidgets('App renders with title and loads demo fixtures', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const DeviceDiscoveryApp());

    expect(find.text('Local Discovery'), findsOneWidget);
    expect(find.text('v1.1.0 review console'), findsOneWidget);
    expect(find.text('mDNS / DNS-SD'), findsOneWidget);
    expect(find.text('SSDP'), findsAtLeastNWidgets(1));
    expect(find.text('WS-Discovery'), findsOneWidget);
    expect(find.text('UPnP metadata'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);

    // Tap Load Demo Fixtures button
    final demoBtn = find.byTooltip('Load demo Wi-Fi & IoT devices');
    expect(demoBtn, findsOneWidget);
    await tester.tap(demoBtn);
    await tester.pumpAndSettle();

    // Verify summary count updated to 4
    expect(find.text('4'), findsWidgets);

    // Verify demo devices and services rendered
    expect(find.text('HP Color LaserJet Pro M479'), findsAtLeastNWidgets(1));
    expect(find.text('Living Room Apple TV'), findsAtLeastNWidgets(1));
    expect(find.text('Philips Hue Bridge'), findsAtLeastNWidgets(1));
    expect(find.text('Front Door Camera'), findsAtLeastNWidgets(1));
  });
}
