import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petvault/main.dart';
import 'package:petvault/petvault_api.dart';

void main() {
  testWidgets('seller can read and reply to a marketplace conversation',
      (WidgetTester tester) async {
    final previousApi = PetVaultApp.api;
    final messages = <Map<String, Object>>[
      <String, Object>{
        'id': 'message-1',
        'senderId': 'buyer-id',
        'body': 'Is the listing still available?',
      },
    ];
    final testApi = PetVaultApi(
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return http.Response(
            jsonEncode(<String, Object>{
              'token': 'test-token',
              'user': <String, Object>{
                'id': 'seller-id',
                'email': 'seller@example.test',
                'displayName': 'Seller',
                'roles': <String>['seller'],
                'verified': true,
              },
            }),
            200,
          );
        }
        if (request.url.path == '/api/listings') {
          return http.Response(
            jsonEncode(<String, Object>{'listings': <Object>[]}),
            200,
          );
        }
        if (request.url.path == '/api/my/listings') {
          expect(request.headers['authorization'], 'Bearer test-token');
          return http.Response(
            jsonEncode(<String, Object>{'listings': <Object>[]}),
            200,
          );
        }
        expect(request.headers['authorization'], 'Bearer test-token');
        if (request.method == 'GET' &&
            request.url.path == '/api/conversations') {
          return http.Response(
            jsonEncode(<String, Object>{
              'conversations': <Object>[
                <String, Object>{
                  'id': 'conversation-1',
                  'listingId': 'listing-1',
                  'title': 'Mochi the cat',
                  'lastMessage': 'Is the listing still available?',
                },
              ],
            }),
            200,
          );
        }
        if (request.method == 'GET' &&
            request.url.path == '/api/conversations/conversation-1/messages') {
          return http.Response(
            jsonEncode(<String, Object>{'messages': messages}),
            200,
          );
        }
        if (request.method == 'POST' &&
            request.url.path == '/api/conversations/conversation-1/messages') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['body'], 'Thanks for your interest!');
          messages.add(<String, Object>{
            'id': 'message-2',
            'senderId': 'seller-id',
            'body': body['body'] as String,
          });
          return http.Response(
            jsonEncode(<String, Object>{'message': messages.last}),
            201,
          );
        }
        fail('Unexpected request: ${request.method} ${request.url.path}');
      }),
    );
    PetVaultApp.api = testApi;
    addTearDown(() {
      testApi.dispose();
      PetVaultApp.api = previousApi;
    });

    await testApi.signIn('seller@example.test', 'test-password');
    await tester.pumpWidget(
      const MaterialApp(
        home: VaultPageView(page: AppPage.buyerSellerMessaging),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mochi the cat'), findsOneWidget);
    await tester.tap(find.text('Mochi the cat'));
    await tester.pumpAndSettle();
    expect(find.text('Is the listing still available?'), findsNWidgets(2));

    await tester.enterText(
      find.byType(TextField),
      'Thanks for your interest!',
    );
    await tester.ensureVisible(find.text('Send message'));
    await tester.tap(find.text('Send message'));
    await tester.pumpAndSettle();

    expect(find.text('Thanks for your interest!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
