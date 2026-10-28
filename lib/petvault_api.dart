import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PetVaultApiException implements Exception {
  const PetVaultApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class PetVaultApi {
  PetVaultApi({http.Client? client})
      : _client = client ?? http.Client(),
        baseUrl = _configuredBaseUrl();

  final http.Client _client;
  final String baseUrl;
  String? _token;
  String? pendingEmail;
  String? activeRole;
  String? developmentVerificationCode;
  final Set<String> _availableRoles = <String>{};

  bool get isAuthenticated => _token != null;

  bool canSelectRole(String role) => _availableRoles.contains(role);

  Future<Map<String, dynamic>> register({
    required String displayName,
    required String email,
    required String phone,
    required String password,
  }) async {
    pendingEmail = null;
    developmentVerificationCode = null;
    final response = await _send(
      'POST',
      '/auth/register',
      body: <String, Object?>{
        'displayName': displayName,
        'email': email,
        'phone': phone,
        'password': password,
      },
    );
    pendingEmail = email.trim().toLowerCase();
    developmentVerificationCode =
        response['devCode'] is String ? response['devCode'] as String : null;
    return response;
  }

  Future<Map<String, dynamic>> verifyAccount(String code) async {
    final email = pendingEmail;
    if (email == null) {
      throw const PetVaultApiException(
          'Create an account before entering a verification code.');
    }
    final response = await _send(
      'POST',
      '/auth/verify',
      body: <String, Object?>{'email': email, 'code': code},
    );
    _acceptSession(response);
    pendingEmail = null;
    developmentVerificationCode = null;
    return _userFrom(response);
  }

  Future<Map<String, dynamic>> resendVerificationCode() async {
    final email = pendingEmail;
    if (email == null) {
      throw const PetVaultApiException(
          'Create an account before requesting another verification code.');
    }
    final response = await _send(
      'POST',
      '/auth/resend-code',
      body: <String, Object?>{'email': email},
    );
    developmentVerificationCode =
        response['devCode'] is String ? response['devCode'] as String : null;
    return response;
  }

  Future<Map<String, dynamic>> requestPasswordReset(String email) {
    return _send(
      'POST',
      '/auth/password-reset',
      body: <String, Object?>{'email': email},
    );
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final response = await _send(
      'POST',
      '/auth/login',
      body: <String, Object?>{'email': email, 'password': password},
    );
    _acceptSession(response);
    return _userFrom(response);
  }

  Future<void> selectRole(String role) async {
    await _send(
      'POST',
      '/auth/roles',
      authenticated: true,
      body: <String, Object?>{'role': role},
    );
    activeRole = role;
    _availableRoles.add(role);
  }

  Future<Map<String, dynamic>> submitKyc({
    required String role,
    required String documentReference,
  }) async {
    final response = await _send(
      'POST',
      '/kyc',
      authenticated: true,
      body: <String, Object?>{
        'role': role,
        'documentReference': documentReference,
      },
    );
    _availableRoles.add(role);
    activeRole = role;
    return response;
  }

  Future<List<Map<String, dynamic>>> fetchPets() async {
    final response = await _send('GET', '/pets', authenticated: true);
    return _objectList(response['pets']);
  }

  Future<List<Map<String, dynamic>>> fetchListings() async {
    final response = await _send('GET', '/listings');
    return _objectList(response['listings']);
  }

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final response = await _send('GET', '/products');
    return _objectList(response['products']);
  }

  Future<List<Map<String, dynamic>>> fetchMyProducts() async {
    final response = await _send('GET', '/products/mine', authenticated: true);
    return _objectList(response['products']);
  }

  Future<Map<String, dynamic>> saveProduct({
    String? id,
    required String name,
    required double price,
    required int stock,
    String imageUrl = '',
  }) async {
    final response = await _send(
      id == null ? 'POST' : 'PATCH',
      id == null ? '/products' : '/products/$id',
      authenticated: true,
      body: <String, Object?>{
        'name': name,
        'price': price,
        'stock': stock,
        'imageUrl': imageUrl,
      },
    );
    return _object(response['product']);
  }

  Future<List<Map<String, dynamic>>> fetchProviders(String role) async {
    final response = await _send(
      'GET',
      '/providers?role=${Uri.encodeQueryComponent(role)}',
    );
    return _objectList(response['providers']);
  }

  Future<List<Map<String, dynamic>>> fetchVetAvailability() async {
    final response = await _send('GET', '/veterinary/availability');
    return _objectList(response['availability']);
  }

  Future<Map<String, dynamic>> publishVetAvailability({
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final response = await _send(
      'POST',
      '/veterinary/availability',
      authenticated: true,
      body: <String, Object?>{
        'startsAt': startsAt.toUtc().toIso8601String(),
        'endsAt': endsAt.toUtc().toIso8601String(),
      },
    );
    return _object(response['availability']);
  }

  Future<List<Map<String, dynamic>>> fetchAppointments() async {
    final response = await _send(
      'GET',
      '/veterinary/appointments',
      authenticated: true,
    );
    return _objectList(response['appointments']);
  }

  Future<Map<String, dynamic>> bookVetAppointment({
    required String availabilityId,
    required String petId,
    required String type,
  }) async {
    final response = await _send(
      'POST',
      '/veterinary/appointments',
      authenticated: true,
      body: <String, Object?>{
        'availabilityId': availabilityId,
        'petId': petId,
        'type': type,
      },
    );
    return _object(response['appointment']);
  }

  Future<Map<String, dynamic>> completeVetAppointment({
    required String appointmentId,
    required String notes,
  }) async {
    final response = await _send(
      'POST',
      '/veterinary/appointments/$appointmentId/notes',
      authenticated: true,
      body: <String, Object?>{'notes': notes},
    );
    return _object(response['appointment']);
  }

  Future<List<Map<String, dynamic>>> fetchBookings() async {
    final response = await _send(
      'GET',
      '/sitting/bookings',
      authenticated: true,
    );
    return _objectList(response['bookings']);
  }

  Future<Map<String, dynamic>> createBooking({
    required String sitterId,
    required String petId,
    required DateTime startsAt,
    required DateTime endsAt,
    required String arrangement,
    required String instructions,
    required String emergencyName,
    required String emergencyPhone,
  }) async {
    final response = await _send(
      'POST',
      '/sitting/bookings',
      authenticated: true,
      body: <String, Object?>{
        'sitterId': sitterId,
        'petId': petId,
        'startsAt': startsAt.toUtc().toIso8601String(),
        'endsAt': endsAt.toUtc().toIso8601String(),
        'arrangement': arrangement,
        'instructions': instructions,
        'emergencyName': emergencyName,
        'emergencyPhone': emergencyPhone,
      },
    );
    return _object(response['booking']);
  }

  Future<Map<String, dynamic>> updateBookingStatus(
      String bookingId, String status) async {
    final response = await _send(
      'PATCH',
      '/sitting/bookings/$bookingId/status',
      authenticated: true,
      body: <String, Object?>{'status': status},
    );
    return _object(response['booking']);
  }

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final response = await _send(
      'GET',
      '/notifications',
      authenticated: true,
    );
    return _objectList(response['notifications']);
  }

  Future<void> markNotificationRead(String id) async {
    await _send(
      'PATCH',
      '/notifications/$id/read',
      authenticated: true,
      body: <String, Object?>{},
    );
  }

  Future<Map<String, dynamic>> createSupportRequest({
    required String topic,
    required String message,
  }) async {
    final response = await _send(
      'POST',
      '/support/requests',
      authenticated: true,
      body: <String, Object?>{'topic': topic, 'message': message},
    );
    return _object(response['request']);
  }

  Future<List<Map<String, dynamic>>> fetchKycSubmissions() async {
    final response = await _send('GET', '/kyc', authenticated: true);
    return _objectList(response['submissions']);
  }

  Future<List<Map<String, dynamic>>> fetchKycQueue() async {
    final response = await _send('GET', '/admin/kyc', authenticated: true);
    return _objectList(response['submissions']);
  }

  Future<Map<String, dynamic>> reviewKyc({
    required String submissionId,
    required String status,
    String reviewNote = '',
  }) async {
    final response = await _send(
      'PATCH',
      '/admin/kyc/$submissionId',
      authenticated: true,
      body: <String, Object?>{
        'status': status,
        'reviewNote': reviewNote,
      },
    );
    return _object(response['submission']);
  }

  Future<List<Map<String, dynamic>>> fetchFavorites() async {
    final response = await _send(
      'GET',
      '/listings/favorites',
      authenticated: true,
    );
    return _objectList(response['listings']);
  }

  Future<void> setFavorite(String listingId, bool favorite) async {
    await _send(
      'PUT',
      '/listings/$listingId/favorite',
      authenticated: true,
      body: <String, Object?>{'favorite': favorite},
    );
  }

  Future<void> reportListing(String listingId, String reason) async {
    await _send(
      'POST',
      '/listings/$listingId/reports',
      authenticated: true,
      body: <String, Object?>{'reason': reason},
    );
  }

  Future<Map<String, dynamic>> createVisitRequest({
    required String listingId,
    required DateTime scheduledAt,
    required String message,
  }) async {
    final response = await _send(
      'POST',
      '/listings/$listingId/visit-requests',
      authenticated: true,
      body: <String, Object?>{
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        'message': message,
      },
    );
    return _object(response['visitRequest']);
  }

  Future<List<Map<String, dynamic>>> fetchVisitRequests() async {
    final response = await _send(
      'GET',
      '/visit-requests',
      authenticated: true,
    );
    return _objectList(response['visitRequests']);
  }

  Future<Map<String, dynamic>> updateVisitRequestStatus({
    required String visitRequestId,
    required String status,
  }) async {
    final response = await _send(
      'PATCH',
      '/visit-requests/$visitRequestId/status',
      authenticated: true,
      body: <String, Object?>{'status': status},
    );
    return _object(response['visitRequest']);
  }

  Future<List<Map<String, dynamic>>> fetchPetGrants(String petId) async {
    final response = await _send(
      'GET',
      '/pets/$petId/access-grants',
      authenticated: true,
    );
    return _objectList(response['grants']);
  }

  Future<Map<String, dynamic>> grantPetAccess({
    required String petId,
    required String recipientId,
    required List<String> sections,
    DateTime? expiresAt,
  }) async {
    final response = await _send(
      'POST',
      '/pets/$petId/access-grants',
      authenticated: true,
      body: <String, Object?>{
        'recipientId': recipientId,
        'sections': sections,
        if (expiresAt != null) 'expiresAt': expiresAt.toUtc().toIso8601String(),
      },
    );
    return _object(response['grant']);
  }

  Future<void> revokePetAccess(String petId, String recipientId) async {
    await _send(
      'DELETE',
      '/pets/$petId/access-grants/$recipientId',
      authenticated: true,
    );
  }

  Future<void> deletePet(String petId) async {
    await _send('DELETE', '/pets/$petId', authenticated: true);
  }

  Future<List<Map<String, dynamic>>> fetchOrders() async {
    final response = await _send('GET', '/orders', authenticated: true);
    return _objectList(response['orders']);
  }

  Future<Map<String, dynamic>> createOrder(
      Map<String, int> quantitiesByProductId) async {
    final response = await _send(
      'POST',
      '/orders',
      authenticated: true,
      body: <String, Object?>{
        'items': quantitiesByProductId.entries
            .map((entry) => <String, Object?>{
                  'productId': entry.key,
                  'quantity': entry.value,
                })
            .toList(),
      },
    );
    return _object(response['order']);
  }

  Future<Map<String, dynamic>> payOrder(
    String orderId, {
    bool simulateUnavailable = false,
  }) async {
    final response = await _send(
      'POST',
      '/orders/$orderId/pay',
      authenticated: true,
      body: <String, Object?>{'simulateUnavailable': simulateUnavailable},
    );
    return _object(response['order']);
  }

  Future<Map<String, dynamic>> updateOrderStatus(
      String orderId, String status) async {
    final response = await _send(
      'PATCH',
      '/orders/$orderId/status',
      authenticated: true,
      body: <String, Object?>{'status': status},
    );
    return _object(response['order']);
  }

  Future<List<Map<String, dynamic>>> fetchMyListings() async {
    final response = await _send('GET', '/listings/mine', authenticated: true);
    return _objectList(response['listings']);
  }

  Future<Map<String, dynamic>> createListing({
    required String title,
    required String species,
    required String breed,
    required String city,
    required double price,
    required String age,
    required String imageUrl,
    required String healthNotes,
  }) async {
    final response = await _send(
      'POST',
      '/listings',
      authenticated: true,
      body: <String, Object?>{
        'title': title,
        'species': species,
        'breed': breed,
        'city': city,
        'price': price,
        'age': age,
        'imageUrl': imageUrl,
        'healthNotes': healthNotes,
      },
    );
    return _object(response['listing']);
  }

  Future<Map<String, dynamic>> updateListing({
    required String id,
    required String title,
    required String species,
    required String breed,
    required String city,
    required double price,
    required String age,
    required String imageUrl,
    required String healthNotes,
  }) async {
    final response = await _send(
      'PATCH',
      '/listings/$id',
      authenticated: true,
      body: <String, Object?>{
        'title': title,
        'species': species,
        'breed': breed,
        'city': city,
        'price': price,
        'age': age,
        'imageUrl': imageUrl,
        'healthNotes': healthNotes,
      },
    );
    return _object(response['listing']);
  }

  Future<List<Map<String, dynamic>>> fetchAdminListingsForModeration() async {
    final response = await _send(
      'GET',
      '/admin/listings/moderation',
      authenticated: true,
    );
    return _objectList(response['listings']);
  }

  Future<Map<String, dynamic>> moderateListing({
    required String id,
    required String status,
    String reviewNote = '',
  }) async {
    final response = await _send(
      'PATCH',
      '/admin/listings/$id/moderation',
      authenticated: true,
      body: <String, Object?>{
        'status': status,
        'reviewNote': reviewNote,
      },
    );
    return _object(response['listing']);
  }

  Future<Map<String, dynamic>> createPet({
    required String name,
    required String species,
    required String breed,
    required String age,
    required String sex,
    required double weightKg,
    required String microchip,
  }) async {
    final response = await _send(
      'POST',
      '/pets',
      authenticated: true,
      body: <String, Object?>{
        'name': name,
        'species': species,
        'breed': breed,
        'age': age,
        'sex': sex,
        'weightKg': weightKg,
        'microchip': microchip,
      },
    );
    return _object(response['pet']);
  }

  Future<Map<String, dynamic>> updatePet({
    required String id,
    required String name,
    required String species,
    required String breed,
    required String age,
    required String sex,
    required double weightKg,
    required String microchip,
  }) async {
    final response = await _send(
      'PATCH',
      '/pets/$id',
      authenticated: true,
      body: <String, Object?>{
        'name': name,
        'species': species,
        'breed': breed,
        'age': age,
        'sex': sex,
        'weightKg': weightKg,
        'microchip': microchip,
      },
    );
    return _object(response['pet']);
  }

  Future<List<Map<String, dynamic>>> fetchHealthRecords(String petId) async {
    final response = await _send(
      'GET',
      '/pets/$petId/health-records',
      authenticated: true,
    );
    return _objectList(response['records']);
  }

  Future<Map<String, dynamic>> createHealthRecord({
    required String petId,
    required String title,
    required String type,
    required String provider,
    required DateTime date,
    DateTime? nextDueAt,
    String? attachmentName,
  }) async {
    final response = await _send(
      'POST',
      '/pets/$petId/health-records',
      authenticated: true,
      body: <String, Object?>{
        'title': title,
        'type': type,
        'provider': provider,
        'date': _dateOnly(date),
        if (nextDueAt != null) 'nextDueAt': _dateOnly(nextDueAt),
        if (attachmentName != null) 'attachmentName': attachmentName,
      },
    );
    return _object(response['record']);
  }

  void signOut() {
    _token = null;
    pendingEmail = null;
    activeRole = null;
    developmentVerificationCode = null;
    _availableRoles.clear();
  }

  static String _configuredBaseUrl() {
    const configured = String.fromEnvironment('PETVAULT_API_BASE_URL');
    if (configured.isNotEmpty) return configured;

    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
        return 'http://127.0.0.1:3000/api';
      }
      return '${Uri.base.origin}/api';
    }

    return 'http://127.0.0.1:3000/api';
  }

  void dispose() => _client.close();

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    bool authenticated = false,
    Map<String, Object?>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (authenticated && _token != null) 'Authorization': 'Bearer $_token',
      if (authenticated && activeRole != null) 'X-Active-Role': activeRole!,
    };
    http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers);
        case 'POST':
          response =
              await _client.post(uri, headers: headers, body: jsonEncode(body));
        case 'PATCH':
          response = await _client.patch(uri,
              headers: headers, body: jsonEncode(body));
        case 'PUT':
          response =
              await _client.put(uri, headers: headers, body: jsonEncode(body));
        case 'DELETE':
          response = await _client.delete(uri, headers: headers);
        default:
          throw StateError('Unsupported API method: $method');
      }
    } on http.ClientException catch (error) {
      throw PetVaultApiException(
          'Could not reach PetVault API at $baseUrl. Check that the backend is running. (${error.message})');
    }

    final decoded =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error'] as String? ?? 'The request failed.'
          : 'The request failed.';
      throw PetVaultApiException(message, statusCode: response.statusCode);
    }
    return _object(decoded);
  }

  void _acceptSession(Map<String, dynamic> response) {
    final token = response['token'];
    if (token is! String || token.isEmpty) {
      throw const PetVaultApiException(
          'The API response did not include a sign-in token.');
    }
    _token = token;
    final user = _object(response['user']);
    final roles = user['roles'];
    if (roles is! List<Object?> || roles.any((role) => role is! String)) {
      _token = null;
      throw const PetVaultApiException(
          'The API response did not include valid account roles.');
    }
    _availableRoles
      ..clear()
      ..addAll(roles.cast<String>());
    if (_availableRoles.isEmpty) {
      _token = null;
      throw const PetVaultApiException(
          'The API account has no assigned roles.');
    }
    activeRole =
        _availableRoles.contains('owner') ? 'owner' : _availableRoles.first;
  }

  Map<String, dynamic> _userFrom(Map<String, dynamic> response) =>
      _object(response['user']);

  static Map<String, dynamic> _object(Object? value) {
    if (value is Map<String, dynamic>) return value;
    throw const PetVaultApiException('The API returned an invalid response.');
  }

  static List<Map<String, dynamic>> _objectList(Object? value) {
    if (value is List<Object?>) {
      return value.map(_object).toList(growable: false);
    }
    throw const PetVaultApiException(
        'The API returned an invalid list response.');
  }

  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
