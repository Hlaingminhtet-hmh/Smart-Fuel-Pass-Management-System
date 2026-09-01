import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../models/fuel_result.dart';
import '../../models/fuel_price.dart';
import '../../models/qr_verification.dart';
import '../../models/station_session.dart';
import '../../models/station_report.dart';

class ApiClient {
  static const String baseUrl = 'http://192.168.9.121:9091';
  static const String _tokenKey = 'station_auth_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  const ApiClient();

  Future<StationSession> loginStation({
    required String operatorCode,
    required String password,
  }) async {
    final response = await _post('/api/v1/station/login', {
      'operator_code': operatorCode,
      'password': password,
    }, authenticated: false);

    if (response['success'] != true) {
      throw ApiException(
        response['message']?.toString() ?? 'Station login failed',
        response['code']?.toString() ?? 'LOGIN_FAILED',
        details: response,
      );
    }

    final session = StationSession.fromLoginJson(response);
    if (session.token.isEmpty || session.stationId <= 0) {
      throw const ApiException(
        'Server returned an invalid station session.',
        'INVALID_SESSION',
      );
    }

    await _storage.write(key: _tokenKey, value: session.token);
    return session;
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<QrVerification> verifyVehicleQr(String qrPayload) async {
    final response = await _post('/api/v1/station/qr/verify', {
      'qr_payload': qrPayload,
    });
    if (response['success'] != true) {
      throw ApiException(
        response['message']?.toString() ?? 'Vehicle verification failed',
        response['code']?.toString() ?? 'QR_VERIFY_FAILED',
        details: response,
      );
    }
    return QrVerification.fromJson(response);
  }

  Future<FuelPrice> getCurrentFuelPrice(String fuelType) async {
    final encoded = Uri.encodeQueryComponent(fuelType);
    final response = await _get(
      '/api/v1/station/pricing/current?fuel_type=$encoded',
    );
    if (response['success'] != true) {
      throw ApiException(
        response['message']?.toString() ?? 'Could not load fuel price',
        response['code']?.toString() ?? 'FUEL_PRICE_FAILED',
        details: response,
      );
    }
    return FuelPrice.fromJson(response);
  }

  Future<FuelResult> processFuel({
    required int vehicleId,
    required double liters,
  }) async {
    final response = await _post('/api/v1/station/fuel', {
      'vehicle_id': vehicleId,
      'liters': liters,
    });

    if (response['success'] != true) {
      throw ApiException(
        response['message']?.toString() ?? 'Fuel transaction failed',
        response['code']?.toString() ?? 'FUEL_TRANSACTION_FAILED',
        details: response,
      );
    }

    return FuelResult.fromJson(response);
  }

  Future<StationReport> getStationReport({int days = 1}) async {
    if (days < 1 || days > 30) {
      throw const ApiException('days must be between 1 and 30', 'INVALID_DAYS');
    }
    final response = await _get('/api/v1/station/transactions?days=$days');
    if (response['success'] != true) {
      throw ApiException(
        response['message']?.toString() ?? 'Could not load station report',
        response['code']?.toString() ?? 'REPORT_FAILED',
        details: response,
      );
    }
    return StationReport.fromJson(response);
  }

  Future<Map<String, dynamic>> getStationSession() async {
    return _get('/api/v1/station/session');
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers(authenticated: authenticated);
    try {
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException(
        'Unable to reach station server. Check the Wi-Fi connection.',
        'NETWORK_ERROR',
        details: {'error': error.toString()},
      );
    }
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers(authenticated: true);
    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException(
        'Unable to reach station server. Check the Wi-Fi connection.',
        'NETWORK_ERROR',
        details: {'error': error.toString()},
      );
    }
  }

  Future<Map<String, String>> _headers({required bool authenticated}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (authenticated) {
      final token = await _storage.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final decoded = _decodeBody(response.body);
    final data =
        decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{'data': decoded};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        await _storage.delete(key: _tokenKey);
      }
      throw ApiException(
        data['message']?.toString() ?? 'Request failed',
        data['code']?.toString() ?? 'HTTP_${response.statusCode}',
        statusCode: response.statusCode,
        details: data,
      );
    }
    return data;
  }

  dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(body);
    } on FormatException {
      return {'message': body};
    }
  }
}

class ApiException implements Exception {
  final String message;
  final String code;
  final int? statusCode;
  final Map<String, dynamic> details;

  const ApiException(
    this.message,
    this.code, {
    this.statusCode,
    this.details = const {},
  });

  @override
  String toString() => 'ApiException[$code]: $message';
}
