import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petvault/main.dart';
import 'package:petvault/petvault_api.dart';

void main() {
  testWidgets('registration displays the development code on the OTP screen',
      (WidgetTester tester) async {
    final previousApi = PetVaultApp.api;
    final testApi = PetVaultApi(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/auth/register');
        return http.Response(
          jsonEncode(<String, Object>{
            'message': 'Verification code issued.',
            'devCode': '123456',
          }),
          201,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );
    PetVaultApp.api = testApi;
    addTearDown(() {
      testApi.dispose();
      PetVaultApp.api = previousApi;
    });

    await tester.pumpWidget(const PetVaultApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Taylor Example');
    await tester.enterText(find.byType(TextField).at(1), 'taylor@example.test');
    await tester.enterText(find.byType(TextField).at(2), '+1 555 010 2020');
    await tester.enterText(find.byType(TextField).at(3), 'secure-test-pass');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.text('Local development verification code'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.text('123456'), findsNWidgets(2));
    expect(
        find.text('This code is for local development only.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
