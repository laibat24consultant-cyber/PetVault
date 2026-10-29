<<<<<<< HEAD
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

  testWidgets('admin sign-in does not request owner/vendor orders',
      (WidgetTester tester) async {
    final previousApi = PetVaultApp.api;
    var requestedOrders = false;
    final testApi = PetVaultApi(
      client: MockClient((request) async {
        switch (request.url.path) {
          case '/api/auth/login':
            return http.Response(
              jsonEncode(<String, Object>{
                'token': 'admin-token',
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
          case '/api/orders':
            requestedOrders = true;
            return http.Response(
              jsonEncode(<String, String>{'error': 'Orders are unavailable.'}),
              403,
            );
          case '/api/pets':
            return http.Response(jsonEncode({'pets': <Object>[]}), 200);
          case '/api/listings':
            return http.Response(jsonEncode({'listings': <Object>[]}), 200);
          case '/api/products':
            return http.Response(jsonEncode({'products': <Object>[]}), 200);
          case '/api/admin/kyc':
            return http.Response(jsonEncode({'submissions': <Object>[]}), 200);
          case '/api/admin/listings/moderation':
            return http.Response(jsonEncode({'listings': <Object>[]}), 200);
          default:
            return http.Response('{}', 200);
        }
      }),
    );
    PetVaultApp.api = testApi;
    addTearDown(() {
      testApi.dispose();
      PetVaultApp.api = previousApi;
    });

    await tester.pumpWidget(const PetVaultApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).at(0), 'admin@example.test');
    await tester.enterText(find.byType(TextField).at(1), 'secure-password');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(requestedOrders, isFalse);
    expect(find.text('Admin dashboard'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('forgot password completes reset request and confirmation',
      (WidgetTester tester) async {
    final previousApi = PetVaultApp.api;
    var requestedReset = false;
    var confirmedReset = false;
    final testApi = PetVaultApi(
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/password-reset') {
          requestedReset = true;
          expect(jsonDecode(request.body), <String, String>{
            'email': 'taylor@example.test',
          });
          return http.Response(
            jsonEncode(<String, Object>{
              'message': 'A password reset code has been issued.',
              'devCode': '654321',
            }),
            200,
          );
        }
        if (request.url.path == '/api/auth/password-reset/confirm') {
          confirmedReset = true;
          expect(jsonDecode(request.body), <String, String>{
            'email': 'taylor@example.test',
            'code': '654321',
            'newPassword': 'new-secure-password',
          });
          return http.Response(
            jsonEncode(<String, Object>{
              'changed': true,
              'message': 'Password updated. Sign in with your new password.',
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      }),
    );
    PetVaultApp.api = testApi;
    addTearDown(() {
      testApi.dispose();
      PetVaultApp.api = previousApi;
    });

    await tester.pumpWidget(const PetVaultApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'taylor@example.test');
    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset your password'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'taylor@example.test',
    );
    await tester.ensureVisible(find.text('Send reset code'));
    await tester.tap(find.text('Send reset code'));
    await tester.pumpAndSettle();
    expect(requestedReset, isTrue);
    expect(find.text('Local development reset code'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), '654321');
    await tester.enterText(find.byType(TextField).at(2), 'new-secure-password');
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Update password'));
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();

    expect(confirmedReset, isTrue);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
=======
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
>>>>>>> 24ecb6467fbec18fd7e609611217a71dd686272b
