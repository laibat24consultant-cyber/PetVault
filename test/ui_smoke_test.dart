import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petvault/main.dart';
import 'package:petvault/petvault_api.dart';

void main() {
  testWidgets('all app pages render at mobile and desktop widths',
      (WidgetTester tester) async {
    final previousApi = PetVaultApp.api;
    final testApi = PetVaultApi(
      client: MockClient((request) async {
        final key = request.url.path.split('/').last;
        final collection = switch (key) {
          'listings' => 'listings',
          'products' => 'products',
          'providers' => 'providers',
          _ => null,
        };
        return http.Response(
          jsonEncode(collection == null
              ? <String, Object>{}
              : {collection: <Object>[]}),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );
    PetVaultApp.api = testApi;
    PetVaultApp.store.signOut();
    addTearDown(() {
      testApi.dispose();
      PetVaultApp.api = previousApi;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final configurations = <(Size, double)>[
      (const Size(320, 720), 1),
      (const Size(360, 800), 1),
      (const Size(360, 800), 1.5),
      (const Size(1280, 800), 1),
    ];
    for (final (size, textScale) in configurations) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      for (final page in AppPage.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(textScale),
              ),
              child: VaultPageView(page: page),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final exception = tester.takeException();
        expect(
          exception,
          isNull,
          reason:
              '${page.name} failed at ${size.width}px wide with text scale $textScale',
        );
      }
    }
  });
}
