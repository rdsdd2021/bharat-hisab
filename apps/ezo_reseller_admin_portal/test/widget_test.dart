import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezo_reseller_admin_portal/src/superadmin_auth_screen.dart';
import 'package:ezo_reseller_admin_portal/src/reseller_dashboard_screen.dart';

void main() {
  testWidgets('SuperadminAuthScreen renders and allows login submission', (WidgetTester tester) async {
    bool authenticated = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SuperadminAuthScreen(
          onAuthenticated: () {
            authenticated = true;
          },
        ),
      ),
    );

    expect(find.text('BharatHisab Control Tower'), findsOneWidget);
    expect(find.text('Sign In to Control Tower'), findsOneWidget);

    // Tap sign in
    await tester.tap(find.text('Sign In to Control Tower'));
    await tester.pumpAndSettle();

    expect(authenticated, isTrue);
  });

  testWidgets('ResellerDashboardScreen renders tabs, KPIs and issue key dialog', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: ResellerDashboardScreen(),
      ),
    );

    expect(find.text('Issue Commercial Key'), findsWidgets);
    expect(find.text('TOTAL FLEET SALES (TODAY)'), findsOneWidget);

    // Open Issue Commercial Key modal
    await tester.tap(find.text('Issue Commercial Key').first);
    await tester.pumpAndSettle();

    // Verify modal elements
    expect(find.text('Subscription Tier'), findsOneWidget);
    expect(find.text('Generate Key'), findsOneWidget);
  });
}
