import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petvault/petvault_api.dart';

void main() {
  test('authenticated requests send the bearer token and active role',
      () async {
    var callCount = 0;
    final client = MockClient((request) async {
      callCount += 1;
      if (callCount == 1) {
        expect(request.headers['authorization'], isNull);
        return http.Response(
          jsonEncode({
            'token': 'demo-token',
            'user': {
              'roles': <String>['owner']
            },
          }),
          200,
        );
      }

      expect(request.headers['authorization'], 'Bearer demo-token');
      expect(request.headers['x-active-role'], 'owner');
      return http.Response(jsonEncode({'pets': <Map<String, dynamic>>[]}), 200);
    });

    final api = PetVaultApi(client: client);
    await api.signIn('owner@petvault.demo', 'demo1234');
    await api.fetchPets();

    expect(callCount, 2);
    api.dispose();
  });
}
