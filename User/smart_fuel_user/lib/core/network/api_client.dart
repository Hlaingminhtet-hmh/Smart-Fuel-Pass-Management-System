import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../models/transaction.dart';
import '../../models/user.dart';
import '../../models/vehicle.dart';

class ApiClient {
  static const String baseUrl = 'http://192.168.9.121:9091';

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  Future<Map<String, String>> _headers() async {
    final token = await storage.read(key: 'user_token');

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers();

    late http.Response response;

    if (method == 'POST') {
      response = await http
          .post(uri, headers: headers, body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 10));
    } else {
      response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
    }

    final data =
        response.body.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['message']?.toString() ??
            'Request failed (${response.statusCode})',
      );
    }

    return data;
  }

  Future<AppUser> register(
    String nationalId,
    String name,
    String phone,
    String password,
  ) async {
    final data = await _request(
      'POST',
      '/api/v1/user/register',
      body: {
        'national_id': nationalId,
        'name': name,
        'phone': phone,
        'password': password,
      },
    );

    await storage.write(key: 'user_token', value: data['token']?.toString());

    return AppUser.fromJson(Map<String, dynamic>.from(data['user']));
  }

  Future<AppUser> login(String nationalId, String password) async {
    final data = await _request(
      'POST',
      '/api/v1/user/login',
      body: {'national_id': nationalId, 'password': password},
    );

    await storage.write(key: 'user_token', value: data['token']?.toString());

    return AppUser.fromJson(Map<String, dynamic>.from(data['user']));
  }

  Future<List<UserVehicle>> vehicles() async {
    final data = await _request('GET', '/api/v1/user/vehicles');

    return (data['vehicles'] as List? ?? const [])
        .map((item) => UserVehicle.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // Keep your latest 4-field vehicle check implementation.
  Future<UserVehicle> checkVehicle({
    required String ownerName,
    required String nationalId,
    required String plateNumber,
    required String vehicleType,
  }) async {
    final data = await _request(
      'POST',
      '/api/v1/user/vehicles/check',
      body: {
        'owner_name': ownerName,
        'national_id': nationalId,
        'plate_number': plateNumber,
        'vehicle_type': vehicleType,
      },
    );

    return UserVehicle.fromJson(Map<String, dynamic>.from(data['vehicle']));
  }

  // Keep your latest 4-field vehicle claim implementation.
  Future<UserVehicle> claimVehicle({
    required String ownerName,
    required String nationalId,
    required String plateNumber,
    required String vehicleType,
  }) async {
    final data = await _request(
      'POST',
      '/api/v1/user/vehicles/claim',
      body: {
        'owner_name': ownerName,
        'national_id': nationalId,
        'plate_number': plateNumber,
        'vehicle_type': vehicleType,
      },
    );

    return UserVehicle.fromJson(Map<String, dynamic>.from(data['vehicle']));
  }

  Future<List<UserTransaction>> history() async {
    final data = await _request('GET', '/api/v1/user/history');

    return (data['transactions'] as List? ?? const [])
        .map(
          (item) => UserTransaction.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<Map<String, dynamic>> qr(int vehicleId) {
    return _request('GET', '/api/v1/user/vehicles/$vehicleId/qr');
  }

  Future<void> logout() async {
    await storage.delete(key: 'user_token');
  }
}
