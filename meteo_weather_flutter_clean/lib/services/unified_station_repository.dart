import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/unified_station_models.dart';

typedef StationAccessTokenProvider = Future<String?> Function();

/// Authenticated adapter for docs/unified-stations-api.md.
/// A public Supabase anon key is deliberately not accepted as a user token.
class UnifiedStationRepository {
  UnifiedStationRepository({
    required Uri apiBaseUri,
    required StationAccessTokenProvider accessTokenProvider,
    http.Client? client,
  }) : _apiBaseUri = apiBaseUri,
       _accessTokenProvider = accessTokenProvider,
       _client = client ?? http.Client();

  final Uri _apiBaseUri;
  final StationAccessTokenProvider _accessTokenProvider;
  final http.Client _client;
  void dispose() => _client.close();

  Future<List<UnifiedWeatherStation>> fetchStations() async {
    final body = await _getJson(_apiBaseUri.resolve('/api/v1/stations'));
    if (body is! List) throw const FormatException('Stations API must return a JSON array');
    return body.whereType<Map>()
        .map((row) => UnifiedWeatherStation.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<List<StationObservation>> fetchObservations(
    String stationId, {
    StationObservationFilter filter = StationObservationFilter.all,
    int limit = 500,
  }) async {
    if (stationId.trim().isEmpty) throw ArgumentError.value(stationId, 'stationId', 'must not be blank');
    if (limit < 1 || limit > 2000) throw ArgumentError.value(limit, 'limit', 'must be between 1 and 2000');
    final uri = _apiBaseUri.resolve(
      '/api/v1/stations/${Uri.encodeComponent(stationId)}/observations',
    ).replace(queryParameters: {
      'source': filter == StationObservationFilter.all ? 'all' : filter.name,
      'limit': '$limit',
    });
    final body = await _getJson(uri);
    if (body is! List) throw const FormatException('Observations API must return a JSON array');
    final rows = body.whereType<Map>()
        .map((row) => StationObservation.fromJson(Map<String, dynamic>.from(row)))
        .where((row) => row.stationId == stationId && filter.accepts(row.source))
        .toList();
    rows.sort((a, b) => b.observedAt.compareTo(a.observedAt));
    return rows;
  }

  Future<dynamic> _getJson(Uri uri) async {
    final token = (await _accessTokenProvider())?.trim();
    if (token == null || token.isEmpty) {
      throw StateError('يلزم تسجيل الدخول للحصول على رمز وصول صالح إلى بيانات المحطات');
    }
    final response = await _client.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 20));
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw StateError('رفض الخادم الوصول إلى بيانات المحطات (${response.statusCode})');
    }
    if (response.statusCode != 200) {
      throw StateError('تعذر جلب بيانات المحطات (${response.statusCode})');
    }
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw const FormatException('Unified stations API returned invalid JSON');
    }
  }
}
