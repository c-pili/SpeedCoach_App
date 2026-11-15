import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/models/device_models.dart';
import '../../core/services/parsers.dart';
import '../../core/utils/date_time.dart';

class StravaAuth {
  static const String _clientId = 'YOUR_STRAVA_CLIENT_ID';
  static const String _clientSecret = 'YOUR_STRAVA_CLIENT_SECRET';
  static const String _redirectUri = 'speedcoach://strava-auth';
  static const String _authUrl = 'https://www.strava.com/oauth/authorize';
  static const String _tokenUrl = 'https://www.strava.com/oauth/token';
  static const String _apiBase = 'https://www.strava.com/api/v3';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _accessTokenKey = 'strava_access_token';
  static const String _refreshTokenKey = 'strava_refresh_token';
  static const String _expiresAtKey = 'strava_expires_at';

  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: _accessTokenKey);
    final expiresAt = await _storage.read(key: _expiresAtKey);
    if (token == null || expiresAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch < int.parse(expiresAt) * 1000;
  }

  Future<String?> getValidToken() async {
    if (await isAuthenticated()) {
      return _storage.read(key: _accessTokenKey);
    }
    return await _refreshAccessToken();
  }

  Future<String?> _refreshAccessToken() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return null;

    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storeTokens(data);
        return data['access_token'];
      }
    } catch (_) {}
    return null;
  }

  Future<void> _storeTokens(Map<String, dynamic> data) async {
    await _storage.write(key: _accessTokenKey, value: data['access_token']);
    await _storage.write(key: _refreshTokenKey, value: data['refresh_token']);
    await _storage.write(key: _expiresAtKey, value: data['expires_at'].toString());
  }

  Future<void> exchangeCode(String code) async {
    final response = await http.post(
      Uri.parse(_tokenUrl),
      body: {
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'code': code,
        'grant_type': 'authorization_code',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _storeTokens(data);
    } else {
      throw Exception('Failed to exchange code: ${response.body}');
    }
  }

  String getAuthUrl() {
    return '$_authUrl?client_id=$_clientId&redirect_uri=$_redirectUri'
        '&response_type=code&scope=read,activity:write,activity:read_all'
        '&approval_prompt=force';
  }

  Future<void> logout() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresAtKey);
  }
}

class StravaExportService {
  final StravaAuth _auth = StravaAuth();
  static const String _apiBase = 'https://www.strava.com/api/v3';

  Future<String> uploadActivity(ActivitySession session, {String sportType = 'row'}) async {
    final token = await _auth.getValidToken();
    if (token == null) {
      throw Exception('Not authenticated with Strava');
    }

    final tcxContent = TcxGenerator.generate(session.copyWith(sportType: sportType));
    final tcxBytes = utf8.encode(tcxContent);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_apiBase/uploads'),
    );
    
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['data_type'] = 'tcx';
    request.fields['name'] = 'SpeedCoach ${DateTimeUtils.formatDateOnly(session.startTime)}';
    request.fields['description'] = 'Imported from SpeedCoach ESP32C3';
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      tcxBytes,
      filename: 'activity_${session.id}.tcx',
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['id'] != null) {
        return 'Activity uploaded successfully (ID: ${data['id']})';
      }
      return 'Upload initiated: ${data['status'] ?? 'pending'}';
    } else {
      throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>?> getAthlete() async {
    final token = await _auth.getValidToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$_apiBase/athlete'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getActivities({int page = 1, int perPage = 30}) async {
    final token = await _auth.getValidToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$_apiBase/athlete/activities?page=$page&per_page=$perPage'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }
}