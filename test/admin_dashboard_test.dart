import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petvault/main.dart';
import 'package:petvault/petvault_api.dart';

void main() {
  testWidgets('dashboard user metric opens live user management',
      (WidgetTester tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;

    final previousApi = PetVaultApp.api;
    var usersRequested = false;
    var productsRequested = false;
    final testApi = PetVaultApi(
      client: MockClient((request) async {
        switch (request.url.path) {
          case '/api/auth/login':
            return http.Response(
              jsonEncode(<String, Object>{
                'token': 'admin-test-token',
                'user': <String, Object>{
                  'id': 'admin-user',
                  'email': 'admin@example.test',
                  'displayName': 'Admin',
                  'roles': <String>['admin'],
                  'verified': true,
                },
              }),
              200,
            );
          case '/api/admin/dashboard':
            return http.Response(
              jsonEncode(<String, Object>{
                'stats': <String, int>{
                  'totalUsers': 8,
                  'verifiedUsers': 6,
                  'unverifiedUsers': 2,
                  'suspendedUsers': 0,
                  'sellers': 1,
                  'sitters': 1,
                  'veterinarians': 1,
                  'vendors': 1,
                  'pendingKyc': 0,
                  'openReports': 0,
                  'totalListings': 0,
                  'approvedListings': 0,
                  'pendingListings': 0,
                  'totalBookings': 0,
                  'openBookings': 0,
                  'totalAppointments': 0,
                  'totalOrders': 0,
                  'attentionOrders': 0,
                  'openDisputes': 0,
                  'resolvedDisputes': 0,
                },
              }),
              200,
            );
          case '/api/admin/kyc':
            return http.Response(
              jsonEncode(<String, Object>{'submissions': <Object>[]}),
              200,
            );
          case '/api/admin/users':
            usersRequested = true;
            return http.Response(
              jsonEncode(<String, Object>{
                'items': <Object>[],
                'total': 0,
                'page': 1,
                'pageSize': 25,
                'pages': 0,
              }),
              200,
            );
          case '/api/admin/products':
            productsRequested = true;
            return http.Response(
              jsonEncode(<String, Object>{
                'items': <Object>[
                  <String, Object>{
                    'id': 'product-1',
                    'vendorId': 'vendor-1',
                    'vendorName': 'Vendor Example',
                    'vendorEmail': 'vendor@example.test',
                    'name': 'Healthy pet food',
                    'price': '12.50',
                    'stock': 3,
                    'published': true,
                    'updatedAt': '2026-11-18T00:00:00.000Z',
                  },
                ],
                'total': 1,
                'page': 1,
                'pageSize': 25,
                'pages': 1,
              }),
              200,
            );
          default:
            fail('Unexpected request: ${request.method} ${request.url}');
        }
      }),
    );
    PetVaultApp.api = testApi;
    PetVaultApp.store.signOut();
    addTearDown(() {
      PetVaultApp.store.signOut();
      testApi.dispose();
      PetVaultApp.api = previousApi;
    });

    final user = await testApi.signIn('admin@example.test', 'test-password');
    PetVaultApp.store.activateRemoteSession(user);
    await tester.pumpWidget(
      const MaterialApp(home: VaultPageView(page: AppPage.adminDashboard)),
    );
    await tester.pumpAndSettle();

    final sidebar =
        find.byKey(const ValueKey<String>('petvault-admin-sidebar'));
    expect(sidebar, findsOneWidget);
    final sidebarScroll =
        find.descendant(of: sidebar, matching: find.byType(Scrollable));
    expect(sidebarScroll, findsOneWidget);
    await tester.scrollUntilVisible(
      find.descendant(
        of: sidebar,
        matching: find.text('Disputes & cancellations'),
      ),
      240,
      scrollable: sidebarScroll,
    );
    expect(
      find.descendant(
        of: sidebar,
        matching: find.text('Disputes & cancellations'),
      ),
      findsOneWidget,
    );
    const responsiveViewports = <Size>[
      Size(1024, 768),
      Size(840, 600),
      Size(390, 844),
    ];
    for (final viewport in responsiveViewports) {
      tester.view.physicalSize = viewport;
      await tester.pumpAndSettle();
      expect(
        sidebar,
        viewport.width >= 1024 ? findsOneWidget : findsNothing,
        reason: 'Admin sidebar at $viewport',
      );
      expect(tester.takeException(), isNull,
          reason: 'Admin layout at $viewport');
    }
    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();

    expect(find.text('8'), findsOneWidget);
    final usersMetric =
        find.byKey(const ValueKey<String>('admin-drilldown-users'));
    await tester.ensureVisible(usersMetric);
    await tester.tap(usersMetric);
    await tester.pumpAndSettle();

    expect(usersRequested, isTrue);
    expect(
      find.descendant(of: sidebar, matching: find.text('User management')),
      findsOneWidget,
    );
    final productsNav = find.descendant(
      of: sidebar,
      matching: find.text('Products & vendors'),
    );
    await tester.ensureVisible(productsNav);
    await tester.tap(productsNav);
    await tester.pumpAndSettle();
    expect(productsRequested, isTrue);
    expect(find.text('Healthy pet food'), findsOneWidget);
    final signOut = find.descendant(
      of: sidebar,
      matching: find.text('Sign out'),
    );
    await tester.tap(signOut);
    await tester.pumpAndSettle();
    expect(testApi.isAuthenticated, isFalse);
    expect(find.text('Care for every part of their life.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
