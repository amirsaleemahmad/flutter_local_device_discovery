import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_local_device_discovery_example/main.dart';

void main() {
  testWidgets('App renders with title', (WidgetTester tester) async {
    await tester.pumpWidget(const DeviceDiscoveryApp());

    expect(find.text('Local Device Discovery'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}